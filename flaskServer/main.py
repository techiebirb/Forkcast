import json
import logging
import os
from datetime import timedelta
from pathlib import Path
from typing import Any, List, Mapping, Optional
from urllib.parse import quote_plus, urlparse

import certifi
import requests
from dotenv import load_dotenv
from flask import Flask, g, jsonify, redirect, render_template, request, session, url_for
from google import genai
from google.genai import types
from pydantic import AliasChoices, BaseModel, ConfigDict, Field
from pymongo import MongoClient
from pymongo.collection import Collection
from pymongo.errors import DuplicateKeyError
from werkzeug.security import check_password_hash, generate_password_hash

load_dotenv()


MODEL_NAME = "gemini-3.1-flash-lite"
MONGO_URI = os.environ.get("MONGO_URI", "").strip()
IS_PRODUCTION = os.environ.get("APP_ENV", "").lower() == "production"
logger = logging.getLogger(__name__)

class FoodItem(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    is_food_item: bool = Field(
        default=True,
        description="True if this is actually a food item.",
    )
    name: str = Field(description="Name of the food item.")
    quantity: str = Field(
        default="1 serving",
        description="Quantity of the food item, including units.",
    )
    ingredients: List[str] = Field(default_factory=list)
    calories: float = Field(description="Calories of the food item.")
    proteins: float = Field(
        validation_alias=AliasChoices("proteins", "protein"),
        description="Protein of the food item in grams.",
    )
    carbs: float = Field(
        validation_alias=AliasChoices("carbs", "carbohydrates"),
        description="Carbohydrates of the food item in grams.",
    )
    fat: float = Field(description="Fat of the food item in grams.")
    fiber: float = Field(default=0, description="Fiber of the food item in grams.")
    sugar: float = Field(default=0, description="Sugar of the food item in grams.")


class RestaurantRecommendation(BaseModel):
    name: str = Field(description="Restaurant name.")
    address: str = Field(default="", description="Street address or area.")
    cuisine: str = Field(default="", description="Primary cuisine.")
    why_it_matches: str = Field(
        description="Short explanation of why this restaurant's overall style might fit the user's diet goals. Do not cite specific dishes or macros."
    )
    possible_ideas: str = Field(
        default="",
        description=(
            "A high-level guess of meal types that might work here "
            "(for example grilled proteins or customizable bowls). "
            "No dish names, ingredients, nutrition facts, or macros."
        ),
    )
    website: str = Field(
        default="",
        description=(
            "Official restaurant website URL if known from search. "
            "Leave empty if unknown. Do not invent URLs."
        ),
    )
    doordash_url: str = Field(
        default="",
        description=(
            "DoorDash store page URL if this restaurant is listed on DoorDash. "
            "Leave empty if unknown or not available. Do not invent URLs."
        ),
    )


class UserPreferences(BaseModel):
    """Temporary user targets stored in Flask session (no database)."""

    calories: Optional[float] = Field(default=None, description="Target calories.")
    proteins: Optional[float] = Field(default=None, description="Target protein in grams.")
    carbs: Optional[float] = Field(default=None, description="Target carbs in grams.")
    fat: Optional[float] = Field(default=None, description="Target fat in grams.")
    fiber: Optional[float] = Field(default=None, description="Target fiber in grams.")
    sugar: Optional[float] = Field(default=None, description="Target sugar in grams.")
    halal: bool = False
    kosher: bool = False
    allergies: List[str] = Field(default_factory=list)
    restaurant_name: str = ""
    latitude: Optional[str] = None
    longitude: Optional[str] = None

    def fooditem_targets(self) -> dict:
        return {
            "calories": self.calories,
            "proteins": self.proteins,
            "carbs": self.carbs,
            "fat": self.fat,
            "fiber": self.fiber,
            "sugar": self.sugar,
        }

    def prompt_summary(self) -> str:
        diet = []
        if self.halal:
            diet.append("halal")
        if self.kosher:
            diet.append("kosher")
        allergies = ", ".join(self.allergies) or "none"
        location = "unknown"
        if self.latitude and self.longitude:
            location = f"{self.latitude}, {self.longitude}"
        return (
            f"Macro targets (use None as unconstrained): {self.fooditem_targets()}\n"
            f"Dietary restrictions: {', '.join(diet) or 'none'}\n"
            f"Allergies to avoid: {allergies}\n"
            f"User location: {location}\n"
            f"Restaurant name if provided: {self.restaurant_name or 'none'}"
        )


GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "").strip()


def _load_maps_api_key() -> str:
    """Prefer env, then local Android properties used by the Flutter app."""
    env_key = os.environ.get("GOOGLE_MAPS_API_KEY", "").strip()
    if env_key:
        return env_key

    if IS_PRODUCTION:
        return ""

    candidates = [
        Path(__file__).resolve().parent / ".env",
        Path(__file__).resolve().parent.parent
        / "mobileapp"
        / "android"
        / "local.properties",
    ]
    for path in candidates:
        if not path.is_file():
            continue
        try:
            for raw_line in path.read_text(encoding="utf-8").splitlines():
                line = raw_line.strip()
                if not line.startswith("GOOGLE_MAPS_API_KEY="):
                    continue
                value = line.split("=", 1)[1].strip().strip('"').strip("'")
                if value:
                    return value
        except OSError:
            continue
    return ""


GOOGLE_MAPS_API_KEY = _load_maps_api_key()
client = genai.Client(api_key=GEMINI_API_KEY) if GEMINI_API_KEY else None
mongo_client: Optional[MongoClient] = None

app = Flask(__name__)
_secret_key = os.environ.get("FLASK_SECRET_KEY", "").strip()
if not _secret_key:
    if IS_PRODUCTION:
        raise RuntimeError("FLASK_SECRET_KEY must be set when APP_ENV=production.")
    logger.warning("FLASK_SECRET_KEY not set; using an insecure dev key.")
    _secret_key = "dev-only-insecure-key"
app.secret_key = _secret_key
app.config.update(
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    SESSION_COOKIE_SECURE=IS_PRODUCTION,
    PERMANENT_SESSION_LIFETIME=timedelta(days=30),
)


def wants_json() -> bool:
    if request.is_json:
        return True
    accept = request.headers.get("Accept", "")
    if "application/json" in accept.lower():
        return True
    best = request.accept_mimetypes.best_match(["application/json", "text/html"])
    return best == "application/json"


def request_payload() -> dict:
    data: dict[str, Any] = {}
    if request.is_json:
        body = request.get_json(silent=True) or {}
        if isinstance(body, dict):
            data.update(body)
    data.update(request.form.to_dict())
    return data


def payload_get(payload: Mapping[str, Any], key: str, default: Any = None) -> Any:
    if key in payload:
        return payload[key]
    return default


def json_error(message: str, status: int):
    return jsonify({"error": message}), status


_index_ready = False


def get_users_collection() -> Collection:
    global mongo_client, _index_ready
    if not MONGO_URI:
        raise RuntimeError("MONGO_URI is not configured.")
    if mongo_client is None:
        mongo_client = MongoClient(
            MONGO_URI,
            serverSelectionTimeoutMS=10000,
            tlsCAFile=certifi.where(),
        )
    collection = mongo_client[os.environ.get("MONGO_DB_NAME", "nutrition_app")]["users"]
    if not _index_ready:
        collection.create_index("username", unique=True)
        _index_ready = True
    return collection


def _user_doc() -> dict:
    """Current user's Mongo document, cached for the request."""
    if "user_doc" in g:
        return g.user_doc
    doc: dict = {}
    username = session.get("username")
    if username:
        try:
            doc = get_users_collection().find_one({"username": username}) or {}
        except Exception:
            logger.exception("Could not load user document")
    g.user_doc = doc
    return doc


def _update_user(fields: dict) -> None:
    username = session.get("username")
    if not username:
        return
    try:
        get_users_collection().update_one({"username": username}, {"$set": fields})
    except Exception:
        logger.exception("Could not save user data")
        return
    if "user_doc" in g:
        g.user_doc.update(fields)


def is_safe_redirect(target: Optional[str]) -> bool:
    if not target:
        return False
    parsed = urlparse(target)
    return not parsed.scheme and not parsed.netloc and target.startswith("/") and not target.startswith("//")


@app.before_request
def require_login():
    public_endpoints = {"login_page", "signup_page", "api_login", "api_signup", "healthz", "static"}
    if request.endpoint not in public_endpoints and "username" not in session:
        if wants_json():
            return json_error("Authentication required.", 401)
        return redirect(url_for("login_page", next=request.full_path))


@app.route("/healthz", methods=["GET"])
def healthz():
    return jsonify({"ok": True})


@app.route("/login", methods=["GET"])
def login_page():
    next_url = request.args.get("next", "")
    if "username" in session:
        if wants_json():
            return jsonify({"authenticated": True, "username": session["username"], "next": next_url})
        return redirect(url_for("home"))
    if wants_json():
        return jsonify({"authenticated": False, "username": None, "next": next_url})
    return render_template("login.html", error=None, next_url=next_url)


@app.route("/signup", methods=["GET"])
def signup_page():
    if "username" in session:
        if wants_json():
            return jsonify({"authenticated": True, "username": session["username"]})
        return redirect(url_for("home"))
    if wants_json():
        return jsonify({"authenticated": False, "username": None})
    return render_template("signup.html", error=None)


@app.route("/api/signup", methods=["POST"])
def api_signup():
    payload = request_payload()
    username = str(payload_get(payload, "username") or "").strip()
    password = str(payload_get(payload, "password") or "")
    if len(username) < 3 or len(password) < 4:
        message = "Username must be at least 3 characters and password at least 4 characters."
        if wants_json():
            return json_error(message, 400)
        return render_template("signup.html", error=message), 400

    try:
        get_users_collection().insert_one({
            "username": username,
            "password_hash": generate_password_hash(password),
        })
    except DuplicateKeyError:
        message = "That username is already taken."
        if wants_json():
            return json_error(message, 409)
        return render_template("signup.html", error=message), 409
    except Exception:
        logger.exception("Could not create account")
        message = "Could not create account."
        if wants_json():
            return json_error(message, 503)
        return render_template("signup.html", error=message), 503

    session.clear()
    session["username"] = username
    session.permanent = True
    if wants_json():
        return jsonify({"username": username})
    return redirect(url_for("home"))


@app.route("/api/login", methods=["POST"])
def api_login():
    payload = request_payload()
    username = str(payload_get(payload, "username") or "").strip()
    password = str(payload_get(payload, "password") or "")
    next_url = str(payload_get(payload, "next") or "")
    try:
        user = get_users_collection().find_one({"username": username})
    except Exception:
        logger.exception("Could not log in")
        message = "Could not log in."
        if wants_json():
            return json_error(message, 503)
        return render_template("login.html", error=message, next_url=next_url), 503

    if not user or not check_password_hash(user["password_hash"], password):
        message = "Invalid username or password."
        if wants_json():
            return json_error(message, 401)
        return render_template("login.html", error=message, next_url=next_url), 401

    session.clear()
    session["username"] = user["username"]
    session.permanent = True
    destination = next_url if is_safe_redirect(next_url) else url_for("home")
    if wants_json():
        return jsonify({"username": user["username"], "next": destination})
    return redirect(destination)


@app.route("/api/logout", methods=["POST"])
def api_logout():
    session.clear()
    if wants_json():
        return jsonify({"ok": True})
    return redirect(url_for("login_page"))

MACRO_FIELDS = [
    ("calories", "Calories", "kcal"),
    ("proteins", "Proteins", "g"),
    ("carbs", "Carbs", "g"),
    ("fat", "Fat", "g"),
    ("fiber", "Fiber", "g"),
    ("sugar", "Sugar", "g"),
]


def sanitize_comma_list(text: Optional[str]) -> List[str]:
    if not text:
        return []
    seen = set()
    cleaned = []
    for item in text.split(","):
        value = item.strip().lower()
        if value and value not in seen:
            seen.add(value)
            cleaned.append(value)
    return cleaned


def parse_allergies(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return sanitize_comma_list(",".join(str(item) for item in value))
    return sanitize_comma_list(str(value))


def parse_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return False
    return str(value).strip().lower() in ("on", "true", "1", "yes")


def display_macro(value: Optional[float]) -> str:
    if value is None:
        return ""
    if float(value).is_integer():
        return str(int(value))
    return str(value)


def parse_optional_float(value: Any) -> Optional[float]:
    if value is None or str(value).strip() == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def resolve_restaurant_name(payload: Mapping[str, Any]) -> str:
    choice = str(payload_get(payload, "restaurant_choice") or "").strip()
    typed = str(payload_get(payload, "restaurant_name") or "").strip()
    if typed and choice and typed != choice:
        return typed
    return choice or typed


def parse_preferences(payload: Mapping[str, Any]) -> UserPreferences:
    latitude = payload_get(payload, "latitude")
    longitude = payload_get(payload, "longitude")
    return UserPreferences(
        calories=parse_optional_float(payload_get(payload, "calories")),
        proteins=parse_optional_float(payload_get(payload, "proteins")),
        carbs=parse_optional_float(payload_get(payload, "carbs")),
        fat=parse_optional_float(payload_get(payload, "fat")),
        fiber=parse_optional_float(payload_get(payload, "fiber")),
        sugar=parse_optional_float(payload_get(payload, "sugar")),
        halal=parse_bool(payload_get(payload, "halal")),
        kosher=parse_bool(payload_get(payload, "kosher")),
        allergies=parse_allergies(payload_get(payload, "allergies")),
        restaurant_name=resolve_restaurant_name(payload),
        latitude=(str(latitude).strip() if latitude not in (None, "") else None),
        longitude=(str(longitude).strip() if longitude not in (None, "") else None),
    )


def load_preferences() -> UserPreferences:
    stored = _user_doc().get("preferences")
    if not stored:
        return UserPreferences()
    try:
        return UserPreferences.model_validate(stored)
    except Exception:
        return UserPreferences()


def save_preferences(preferences: UserPreferences) -> None:
    _update_user({"preferences": preferences.model_dump()})


def load_restaurants() -> List[dict]:
    return _user_doc().get("last_restaurants") or []


def save_restaurants(restaurants: List[dict]) -> None:
    _update_user({"last_restaurants": restaurants})


def payload_has_preference_fields(payload: Mapping[str, Any]) -> bool:
    return "calories" in payload or "proteins" in payload or "allergies" in payload


def preferences_from_request() -> UserPreferences:
    if request.method != "POST":
        return load_preferences()

    payload = request_payload()
    if payload_has_preference_fields(payload):
        preferences = parse_preferences(payload)
    else:
        preferences = load_preferences()
        chosen = resolve_restaurant_name(payload)
        if chosen:
            preferences.restaurant_name = chosen

    save_preferences(preferences)
    return preferences


def generate_structured(
    contents: str,
    schema: Any,
    *,
    system_instruction: Optional[str] = None,
    use_maps: bool = False,
    use_search: bool = False,
    latitude: Optional[str] = None,
    longitude: Optional[str] = None,
) -> Any:
    if client is None:
        raise RuntimeError("GEMINI_API_KEY is not configured.")
    api_client = client
    tools: List[dict] = []
    if use_search:
        tools.append({"google_search": {}})
    if use_maps:
        tools.append({"google_maps": {}})

    def _call(with_tools: bool):
        config_kwargs: dict[str, Any] = {
            "response_mime_type": "application/json",
            "response_schema": schema,
        }
        if system_instruction:
            config_kwargs["system_instruction"] = system_instruction
        if with_tools and tools:
            config_kwargs["tools"] = tools
            if latitude and longitude:
                try:
                    config_kwargs["tool_config"] = {
                        "retrieval_config": {
                            "lat_lng": {
                                "latitude": float(latitude),
                                "longitude": float(longitude),
                            }
                        }
                    }
                except (TypeError, ValueError):
                    pass
        return api_client.models.generate_content(
            model=MODEL_NAME,
            contents=contents,
            config=types.GenerateContentConfig(**config_kwargs),
        )

    try:
        response = _call(bool(tools))
    except Exception:
        response = _call(False)

    parsed = response.parsed
    if parsed is not None:
        return parsed

    text = (response.text or "").strip()
    if not text:
        return []
    data = json.loads(text)
    if schema is list[FoodItem]:
        return [FoodItem.model_validate(item) for item in data]
    if schema is list[RestaurantRecommendation]:
        return [RestaurantRecommendation.model_validate(item) for item in data]
    return data


def search_restaurants_with_gemini(preferences: UserPreferences) -> List[RestaurantRecommendation]:
    prompt = (
        "Recommend 5 local restaurants that are likely to have food matching these "
        "nutrition and diet goals. Prefer real nearby places. Judge fit from cuisine, "
        "restaurant type, and general reputation only. Do not look up, guess, or "
        "return menus, dish names, ingredients, or macros.\n\n"
        f"{preferences.prompt_summary()}"
    )
    system = (
        "You are a local dining assistant. Use maps and search only to find nearby "
        "restaurants. Do not inspect menus or estimate nutrition. Avoid suggesting "
        "places that clearly conflict with allergens or halal/kosher when requested. "
        "When search finds an official website or DoorDash store page, include those "
        "URLs; otherwise leave website and doordash_url empty. Never invent URLs. "
        "Return only structured restaurant recommendations."
    )
    result = generate_structured(
        prompt,
        list[RestaurantRecommendation],
        system_instruction=system,
        use_maps=True,
        use_search=True,
        latitude=preferences.latitude,
        longitude=preferences.longitude,
    )
    if not result:
        return []
    if isinstance(result, list):
        return [
            item if isinstance(item, RestaurantRecommendation) else RestaurantRecommendation.model_validate(item)
            for item in result
        ]
    return [RestaurantRecommendation.model_validate(result)]


def check_restaurant_with_gemini(preferences: UserPreferences) -> List[FoodItem]:
    restaurant = preferences.restaurant_name or "the specified restaurant"
    prompt = (
        f"Extract or estimate a typical menu for {restaurant}. Return 8-12 real or "
        "closely estimated dishes with exact macro breakdowns for calories, proteins, "
        "carbs, fat, fiber, and sugar. Prefer official nutrition facts when known. "
        "Skip items that conflict with allergies or dietary restrictions.\n\n"
        f"{preferences.prompt_summary()}"
    )
    system = (
        "You are a nutrition analyst. Return a JSON list of FoodItem objects. "
        "Use grams for proteins, carbs, fat, fiber, and sugar."
    )
    result = generate_structured(
        prompt,
        list[FoodItem],
        system_instruction=system,
        use_maps=bool(preferences.latitude and preferences.longitude),
        use_search=True,
        latitude=preferences.latitude,
        longitude=preferences.longitude,
    )
    if not result:
        return []
    items = result if isinstance(result, list) else [result]
    parsed_items: List[FoodItem] = []
    for item in items:
        food = item if isinstance(item, FoodItem) else FoodItem.model_validate(item)
        if food.is_food_item:
            parsed_items.append(food)
    return parsed_items


def google_maps_search_url(name: str, address: str = "") -> str:
    query = " ".join(part for part in [name.strip(), address.strip()] if part)
    if not query:
        return ""
    return f"https://www.google.com/maps/search/?api=1&query={quote_plus(query)}"


def require_maps_api_key() -> Optional[str]:
    if not GOOGLE_MAPS_API_KEY:
        return None
    return GOOGLE_MAPS_API_KEY


def _places_field_mask() -> str:
    return ",".join(
        [
            "places.id",
            "places.displayName",
            "places.formattedAddress",
            "places.location",
            "places.businessStatus",
            "places.types",
            "places.rating",
            "places.websiteUri",
            "places.googleMapsUri",
            "places.currentOpeningHours",
        ]
    )


def _place_details_field_mask() -> str:
    return ",".join(
        [
            "id",
            "displayName",
            "formattedAddress",
            "location",
            "businessStatus",
            "types",
            "rating",
            "websiteUri",
            "googleMapsUri",
            "currentOpeningHours",
        ]
    )


def _normalize_place_id(value: str) -> str:
    cleaned = (value or "").strip()
    if cleaned.startswith("places/"):
        return cleaned.split("/", 1)[1]
    return cleaned


def _places_new_item(raw: Mapping[str, Any]) -> Optional[dict]:
    location = raw.get("location") or {}
    lat = location.get("latitude")
    lng = location.get("longitude")
    display = raw.get("displayName") or {}
    name = str(display.get("text") or raw.get("name") or "").strip()
    place_id = _normalize_place_id(str(raw.get("id") or "").strip())
    if not name or not place_id or lat is None or lng is None:
        return None

    business_status = str(raw.get("businessStatus") or "OPERATIONAL").upper()
    if business_status in {"CLOSED_PERMANENTLY", "CLOSED_TEMPORARILY"}:
        return None

    opening = raw.get("currentOpeningHours") or {}
    open_now = opening.get("openNow")
    types = [str(item) for item in (raw.get("types") or [])]
    food_types = {
        "restaurant",
        "food",
        "cafe",
        "bakery",
        "meal_takeaway",
        "meal_delivery",
    }
    if types and not food_types.intersection(types):
        return None

    return {
        "place_id": place_id,
        "name": name,
        "address": str(raw.get("formattedAddress") or "").strip(),
        "latitude": float(lat),
        "longitude": float(lng),
        "business_status": business_status or "OPERATIONAL",
        "open_now": open_now if isinstance(open_now, bool) else None,
        "rating": raw.get("rating"),
        "types": types,
        "website": str(raw.get("websiteUri") or "").strip(),
        "maps_url": str(raw.get("googleMapsUri") or "").strip(),
    }


def _places_api_error(response: requests.Response) -> str:
    try:
        payload = response.json()
    except ValueError:
        return response.text.strip() or f"HTTP {response.status_code}"
    if isinstance(payload, Mapping):
        error = payload.get("error")
        if isinstance(error, Mapping):
            message = error.get("message") or error.get("status")
            if message:
                return str(message)
        message = payload.get("error_message") or payload.get("message")
        if message:
            return str(message)
    return f"HTTP {response.status_code}"


def search_google_places(
    *,
    latitude: float,
    longitude: float,
    query: str = "",
    radius_meters: int = 2500,
) -> List[dict]:
    api_key = require_maps_api_key()
    if not api_key:
        raise RuntimeError(
            "GOOGLE_MAPS_API_KEY is not configured on the server. "
            "Add it to mobileapp/android/local.properties or set the "
            "GOOGLE_MAPS_API_KEY environment variable."
        )

    radius = float(max(200, min(int(radius_meters), 10000)))
    cleaned_query = (query or "").strip()
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": api_key,
        "X-Goog-FieldMask": _places_field_mask(),
    }

    if cleaned_query:
        endpoint = "https://places.googleapis.com/v1/places:searchText"
        body: dict[str, Any] = {
            "textQuery": cleaned_query,
            "includedType": "restaurant",
            "maxResultCount": 20,
            "locationBias": {
                "circle": {
                    "center": {"latitude": latitude, "longitude": longitude},
                    "radius": radius,
                }
            },
        }
    else:
        endpoint = "https://places.googleapis.com/v1/places:searchNearby"
        body = {
            "includedTypes": ["restaurant"],
            "maxResultCount": 20,
            "rankPreference": "DISTANCE",
            "locationRestriction": {
                "circle": {
                    "center": {"latitude": latitude, "longitude": longitude},
                    "radius": radius,
                }
            },
        }

    response = requests.post(endpoint, headers=headers, json=body, timeout=20)
    if response.status_code >= 400:
        raise RuntimeError(_places_api_error(response))

    payload = response.json() if response.content else {}
    places: List[dict] = []
    for item in payload.get("places") or []:
        if not isinstance(item, Mapping):
            continue
        parsed = _places_new_item(item)
        if parsed:
            places.append(parsed)
    return places


def fetch_google_place_details(place_id: str) -> dict:
    api_key = require_maps_api_key()
    if not api_key:
        raise RuntimeError(
            "GOOGLE_MAPS_API_KEY is not configured on the server. "
            "Add it to mobileapp/android/local.properties or set the "
            "GOOGLE_MAPS_API_KEY environment variable."
        )
    cleaned = _normalize_place_id(place_id)
    if not cleaned:
        raise ValueError("place_id is required.")

    response = requests.get(
        f"https://places.googleapis.com/v1/places/{cleaned}",
        headers={
            "X-Goog-Api-Key": api_key,
            "X-Goog-FieldMask": _place_details_field_mask(),
        },
        timeout=20,
    )
    if response.status_code >= 400:
        raise RuntimeError(_places_api_error(response))

    result = response.json() if response.content else {}
    if not isinstance(result, Mapping):
        raise RuntimeError("Place details were empty.")

    parsed = _places_new_item(result)
    if not parsed:
        raise RuntimeError(
            "That place is not an active restaurant (closed or incomplete listing)."
        )

    if parsed["business_status"] != "OPERATIONAL":
        raise RuntimeError(
            f"That restaurant is marked {parsed['business_status'].replace('_', ' ').title()} "
            "on Google Maps."
        )
    return parsed


def resolve_restaurant(name: str, restaurants: List[dict]) -> dict:
    """Match a saved recommendation, or return a minimal stub for a typed name."""
    cleaned = (name or "").strip()
    for item in restaurants:
        if (item.get("name") or "").strip() == cleaned:
            return item
    return {
        "name": cleaned,
        "address": "",
        "cuisine": "",
        "why_it_matches": "",
        "possible_ideas": "",
        "website": "",
        "doordash_url": "",
    }


def home_json_payload(preferences: UserPreferences) -> dict:
    return {
        "username": session.get("username"),
        "preferences": preferences.model_dump(),
        "restaurants": load_restaurants(),
    }


@app.route("/", methods=["GET"])
def home():
    preferences = load_preferences()
    if wants_json():
        return jsonify(home_json_payload(preferences))

    preference_values = preferences.model_dump()
    for name, _, _ in MACRO_FIELDS:
        preference_values[name] = display_macro(preference_values.get(name))

    return render_template(
        "home.html",
        preferences=preferences,
        preference_values=preference_values,
        macro_fields=MACRO_FIELDS,
        restaurants=load_restaurants(),
    )


@app.route("/search-restaurants", methods=["GET", "POST"])
def search_restaurants():
    preferences = preferences_from_request()
    error = None
    restaurants = load_restaurants()

    if request.method == "POST":
        try:
            found = search_restaurants_with_gemini(preferences)
            restaurants = [item.model_dump() for item in found]
            save_restaurants(restaurants)
        except Exception:
            logger.exception("Could not search restaurants")
            error = "Could not search restaurants."
            restaurants = []

    if wants_json():
        return jsonify({
            "preferences": preferences.model_dump(),
            "fooditem_targets": preferences.fooditem_targets(),
            "restaurants": restaurants,
            "error": error,
        })

    return render_template(
        "search_restaurants.html",
        preferences=preferences,
        fooditem_targets=preferences.fooditem_targets(),
        restaurants=restaurants,
        error=error,
    )


@app.route("/api/places/search", methods=["POST"])
def api_places_search():
    payload = request_payload()
    try:
        latitude = float(payload_get(payload, "latitude"))
        longitude = float(payload_get(payload, "longitude"))
    except (TypeError, ValueError):
        return json_error("latitude and longitude are required.", 400)

    query = str(payload_get(payload, "query") or "").strip()
    try:
        radius = int(payload_get(payload, "radius_meters") or 2500)
    except (TypeError, ValueError):
        radius = 2500

    try:
        places = search_google_places(
            latitude=latitude,
            longitude=longitude,
            query=query,
            radius_meters=radius,
        )
    except Exception as exc:
        logger.exception("Places search failed")
        return json_error(str(exc) or "Could not search places.", 502)

    return jsonify({"places": places, "count": len(places)})


@app.route("/api/places/details", methods=["POST"])
def api_places_details():
    payload = request_payload()
    place_id = str(payload_get(payload, "place_id") or "").strip()
    if not place_id:
        return json_error("place_id is required.", 400)

    try:
        place = fetch_google_place_details(place_id)
    except ValueError as exc:
        return json_error(str(exc), 400)
    except Exception as exc:
        logger.exception("Place details failed")
        return json_error(str(exc) or "Could not verify that restaurant.", 502)

    return jsonify({"place": place, "verified": True})


@app.route("/check-restaurant", methods=["GET", "POST"])
def check_restaurant():
    preferences = preferences_from_request()
    error = None
    menu_items: List[dict] = _user_doc().get("last_menu_items") or []
    restaurants = load_restaurants()
    active_restaurant = resolve_restaurant(preferences.restaurant_name, restaurants)
    maps_url = google_maps_search_url(
        active_restaurant.get("name") or preferences.restaurant_name,
        active_restaurant.get("address") or "",
    )

    if request.method == "POST":
        if not preferences.restaurant_name:
            error = "Choose a restaurant from the search results or type a restaurant name."
            menu_items = []
        else:
            try:
                found = check_restaurant_with_gemini(preferences)
                menu_items = [item.model_dump() for item in found]
                _update_user({"last_menu_items": menu_items})
            except Exception:
                logger.exception("Could not check that restaurant")
                error = "Could not check that restaurant."
                menu_items = []
            restaurants = load_restaurants()
            active_restaurant = resolve_restaurant(preferences.restaurant_name, restaurants)
            maps_url = google_maps_search_url(
                active_restaurant.get("name") or preferences.restaurant_name,
                active_restaurant.get("address") or "",
            )

    if wants_json():
        return jsonify({
            "preferences": preferences.model_dump(),
            "fooditem_targets": preferences.fooditem_targets(),
            "menu_items": menu_items,
            "restaurants": restaurants,
            "active_restaurant": active_restaurant,
            "maps_url": maps_url,
            "error": error,
        })

    return render_template(
        "check_restaurant.html",
        preferences=preferences,
        fooditem_targets=preferences.fooditem_targets(),
        menu_items=menu_items,
        restaurants=restaurants,
        active_restaurant=active_restaurant,
        maps_url=maps_url,
        error=error,
    )


if __name__ == "__main__":
    app.run(
        debug=not IS_PRODUCTION,
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 8080)),
    )
# closest matching on top