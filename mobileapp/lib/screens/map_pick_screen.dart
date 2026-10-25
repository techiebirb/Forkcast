import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app.dart';
import '../location.dart';
import '../models.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_chips.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_surfaces.dart';
import '../widgets/map_pins.dart';
import 'check_screen.dart';

class MapPickScreen extends StatefulWidget {
  const MapPickScreen({super.key});

  @override
  State<MapPickScreen> createState() => _MapPickScreenState();
}

class _MapPickScreenState extends State<MapPickScreen> {
  final TextEditingController _query = TextEditingController();
  GoogleMapController? _mapController;
  Timer? _debounce;

  LatLng? _userLocation;
  List<MapPlace> _places = [];
  MapPlace? _selected;
  bool _loadingLocation = true;
  bool _searching = false;
  bool _verifying = false;
  String? _locationError;
  bool _searchFailed = false;

  /// Rendered pin images, keyed by number and selection. Cleared when the
  /// theme changes because the pins use theme colors.
  final Map<String, BitmapDescriptor> _pins = {};
  final Set<String> _pinsPending = {};
  Brightness? _pinBrightness;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_pinBrightness != brightness) {
      _pinBrightness = brightness;
      _pins.clear();
      _pinsPending.clear();
    }
    _ensurePins();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  String _pinKey(int number, bool selected) => '$number:$selected';

  /// Renders any pin images that are not ready yet, then rebuilds.
  void _ensurePins() {
    final colors = context.fc;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    for (var i = 0; i < _places.length; i++) {
      final selected = _selected?.placeId == _places[i].placeId;
      final key = _pinKey(i + 1, selected);
      if (_pins.containsKey(key) || !_pinsPending.add(key)) {
        continue;
      }
      buildPinDescriptor(
        number: i + 1,
        selected: selected,
        colors: colors,
        devicePixelRatio: dpr,
      ).then((descriptor) {
        _pinsPending.remove(key);
        if (mounted) {
          setState(() => _pins[key] = descriptor);
        }
      });
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final coords = await requireLocation();
      final location = LatLng(
        double.parse(coords.$1),
        double.parse(coords.$2),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _userLocation = location;
        _loadingLocation = false;
      });
      await _searchPlaces();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingLocation = false;
        _locationError = error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : error.toString();
      });
    }
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _searchPlaces);
  }

  void _clearQuery() {
    _query.clear();
    _debounce?.cancel();
    _searchPlaces();
  }

  Future<void> _searchPlaces() async {
    final location = _userLocation;
    if (location == null) {
      return;
    }
    setState(() {
      _searching = true;
      _searchFailed = false;
    });
    try {
      final session = SessionScope.of(context);
      final places = await session.searchPlaces(
        latitude: location.latitude,
        longitude: location.longitude,
        query: _query.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _places = places;
        // The first result starts selected, as in the design.
        final keep = _selected == null
            ? null
            : places.where((p) => p.placeId == _selected!.placeId);
        _selected = (keep != null && keep.isNotEmpty)
            ? keep.first
            : (places.isEmpty ? null : places.first);
      });
      _ensurePins();
      await _fitToResults(places, location);
    } catch (_) {
      if (mounted) {
        setState(() => _searchFailed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _fitToResults(List<MapPlace> places, LatLng fallback) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    if (places.isEmpty) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(fallback, 14));
      return;
    }
    if (places.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(places.first.latitude, places.first.longitude),
          15,
        ),
      );
      return;
    }
    var minLat = places.first.latitude;
    var maxLat = places.first.latitude;
    var minLng = places.first.longitude;
    var maxLng = places.first.longitude;
    for (final place in places.skip(1)) {
      minLat = minLat < place.latitude ? minLat : place.latitude;
      maxLat = maxLat > place.latitude ? maxLat : place.latitude;
      minLng = minLng < place.longitude ? minLng : place.longitude;
      maxLng = maxLng > place.longitude ? maxLng : place.longitude;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
  }

  void _select(MapPlace place, {bool moveCamera = false}) {
    setState(() => _selected = place);
    _ensurePins();
    if (moveCamera) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(place.latitude, place.longitude),
          16,
        ),
      );
    }
  }

  Set<Marker> get _markers {
    return {
      for (var i = 0; i < _places.length; i++)
        Marker(
          markerId: MarkerId(_places[i].placeId),
          position: LatLng(_places[i].latitude, _places[i].longitude),
          anchor: const Offset(0.5, 1),
          zIndexInt: _selected?.placeId == _places[i].placeId ? 2 : 1,
          consumeTapEvents: true,
          onTap: () => _select(_places[i]),
          icon: _pins[_pinKey(
                i + 1,
                _selected?.placeId == _places[i].placeId,
              )] ??
              BitmapDescriptor.defaultMarker,
        ),
    };
  }

  Future<void> _confirmSelection() async {
    final selected = _selected;
    final location = _userLocation;
    if (selected == null || _verifying) {
      return;
    }
    final session = SessionScope.of(context);
    final router = GoRouter.of(context);
    setState(() => _verifying = true);
    try {
      final verified = await session.verifyPlace(selected.placeId);
      session.setPreferences(
        session.preferences.copyWith(
          latitude: (location?.latitude ?? verified.latitude).toString(),
          longitude: (location?.longitude ?? verified.longitude).toString(),
        ),
      );
      if (!mounted) {
        return;
      }
      router.push(
        '/check-restaurant',
        extra: CheckRequest(
          RestaurantRecommendation(
            name: verified.name,
            address: verified.address,
            website: verified.website,
            latitude: verified.latitude,
            longitude: verified.longitude,
            distanceMiles: selected.distanceMiles,
            walkMinutes: selected.walkMinutes,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        showApiError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final location = _userLocation;
    final media = MediaQuery.of(context);
    final sheetHeight = (media.size.height * 0.52).clamp(320.0, 480.0);

    if (_loadingLocation) {
      return Scaffold(
        backgroundColor: c.mapLand,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FcSpinner(size: 24, color: c.accent),
                      const SizedBox(height: FcSpace.s3),
                      Text(
                        'Finding your location…',
                        style: FcText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: FcSpace.s4,
                left: FcSpace.s4,
                child: _backButton(c),
              ),
            ],
          ),
        ),
      );
    }

    if (location == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              const FcAppBar(backLabel: 'Back to Home'),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(FcSpace.s4),
                    child: FcCard(
                      child: ListState(
                        kind: ListStateKind.error,
                        title: 'We need your location',
                        body: _locationError ??
                            'Location is required to show nearby restaurants.',
                        actionLabel: 'Try again',
                        onAction: _bootstrap,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.mapLand,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: location, zoom: 14),
            style: forkcastMapStyle(c),
            padding: EdgeInsets.only(bottom: sheetHeight),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_places.isNotEmpty) {
                _fitToResults(_places, location);
              }
            },
          ),
          Positioned(
            top: media.padding.top + FcSpace.s4,
            left: FcSpace.s4,
            right: FcSpace.s4,
            child: Row(
              children: [
                _backButton(c),
                const SizedBox(width: FcSpace.s2),
                Expanded(child: _searchBox(c)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: sheetHeight,
            child: _sheet(c),
          ),
        ],
      ),
    );
  }

  Widget _backButton(FcColors c) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FcRadius.pill),
        boxShadow: c.shadowPin,
      ),
      child: FcButton(
        label: 'Back to Home',
        variant: FcButtonVariant.secondary,
        iconOnly: true,
        icon: FcIcons.caretLeft,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  Widget _searchBox(FcColors c) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: FcSpace.s3),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(FcRadius.input),
        border: Border.all(color: c.borderStrong),
        boxShadow: c.shadowPin,
      ),
      child: Row(
        children: [
          FcIcon(FcIcons.magnifyingGlass, size: 20, color: c.textSecondary),
          const SizedBox(width: FcSpace.s2),
          Expanded(
            child: Semantics(
              textField: true,
              label: 'Search restaurants',
              child: TextField(
                controller: _query,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                onSubmitted: (_) => _searchPlaces(),
                cursorColor: c.accent,
                style: FcText.body.copyWith(color: c.textPrimary),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: 'Search restaurants',
                  hintStyle: FcText.body.copyWith(color: c.textSecondary),
                ),
              ),
            ),
          ),
          if (_query.text.isNotEmpty)
            FcButton(
              label: 'Clear search',
              variant: FcButtonVariant.ghost,
              iconOnly: true,
              icon: FcIcons.x,
              onPressed: _clearQuery,
            )
          else
            const SizedBox(width: FcSpace.s3),
        ],
      ),
    );
  }

  Widget _sheet(FcColors c) {
    final query = _query.text.trim();
    final selected = _selected;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FcRadius.sheet),
        ),
        boxShadow: c.shadowRaised,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: FcSpace.s2),
            decoration: BoxDecoration(
              color: c.borderStrong,
              borderRadius: BorderRadius.circular(FcRadius.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FcSpace.s5,
              FcSpace.s3,
              FcSpace.s5,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _sheetHeader(c, query),
            ),
          ),
          Expanded(child: _sheetBody(c)),
          if (!_searching && _places.isNotEmpty && selected != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                FcSpace.s4,
                FcSpace.s3,
                FcSpace.s4,
                FcSpace.s4 + MediaQuery.paddingOf(context).bottom,
              ),
              child: FcButton(
                label: 'Check ${selected.name}',
                large: true,
                block: true,
                loading: _verifying,
                onPressed: _verifying ? null : _confirmSelection,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sheetHeader(FcColors c, String query) {
    final sub = _subStyle(c);
    if (_searching) {
      return Semantics(
        liveRegion: true,
        container: true,
        child: Row(
          children: [
            FcSpinner(color: c.accent),
            const SizedBox(width: FcSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Searching Google Maps…',
                    style: FcText.wordmark.copyWith(color: c.textPrimary),
                  ),
                  Text(
                    query.isEmpty
                        ? 'Looking for restaurants near you'
                        : 'Looking for “$query” near you',
                    style: sub,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (_places.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_places.length} ${_places.length == 1 ? 'result' : 'results'}',
          style: FcText.tabular(FcText.wordmark).copyWith(
            color: c.textPrimary,
          ),
        ),
        Text(
          query.isEmpty
              ? 'Nearby · from Google Maps'
              : 'For “$query” · from Google Maps',
          style: sub,
        ),
      ],
    );
  }

  TextStyle _subStyle(FcColors c) =>
      FcText.caption.copyWith(color: c.textSecondary);

  Widget _sheetBody(FcColors c) {
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(FcSpace.s5, FcSpace.s4, FcSpace.s5, 0),
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: ListState(kind: ListStateKind.loading, rows: 3),
        ),
      );
    }
    if (_searchFailed) {
      return SingleChildScrollView(
        child: ListState(
          kind: ListStateKind.error,
          title: "Couldn't search Google Maps",
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: _searchPlaces,
        ),
      );
    }
    if (_places.isEmpty) {
      return const SingleChildScrollView(
        child: ListState(
          kind: ListStateKind.empty,
          title: 'No active restaurants found nearby',
          body: 'Try a different name, or search for a type of food.',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(FcSpace.s5, FcSpace.s2, FcSpace.s5, 0),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return _PlaceRow(
          number: index + 1,
          place: place,
          selected: _selected?.placeId == place.placeId,
          last: index == _places.length - 1,
          onTap: () => _select(place, moveCamera: true),
        );
      },
    );
  }
}

/// "10 PM" or "9:30 AM" in the device's local time.
String clockLabel(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  final minutes = local.minute == 0
      ? ''
      : ':${local.minute.toString().padLeft(2, '0')}';
  return '$hour$minutes $suffix';
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.number,
    required this.place,
    required this.selected,
    required this.last,
    required this.onTap,
  });

  final int number;
  final MapPlace place;
  final bool selected;
  final bool last;
  final VoidCallback onTap;

  List<InlineSpan> _meta(FcColors c) {
    final parts = <InlineSpan>[];
    void add(InlineSpan span) {
      if (parts.isNotEmpty) {
        parts.add(const TextSpan(text: ' · '));
      }
      parts.add(span);
    }

    if (place.rating != null) {
      add(TextSpan(text: 'Rated ${fcNum(place.rating!)}'));
    }
    final bold = TextStyle(
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
    );
    if (place.openNow == true) {
      add(TextSpan(text: 'Open', style: bold));
      if (place.nextCloseTime != null) {
        parts.add(TextSpan(text: ' until ${clockLabel(place.nextCloseTime!)}'));
      }
    } else if (place.openNow == false) {
      add(TextSpan(text: 'Closed', style: bold));
      if (place.nextOpenTime != null) {
        parts.add(TextSpan(text: ' opens ${clockLabel(place.nextOpenTime!)}'));
      }
    }
    if (place.distanceMiles != null) {
      add(TextSpan(text: '${fcNum(place.distanceMiles!)} mi'));
    }
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final meta = _meta(c);
    return Semantics(
      button: true,
      selected: selected,
      label: '$number, ${place.name}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? c.accent : c.surfaceSunken,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: FcText.tabular(FcText.caption).copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? c.onAccent : c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: FcSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: FcText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Text.rich(
                        TextSpan(children: meta),
                        style: FcText.tabular(FcText.bodySm).copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              FcIcon(FcIcons.caretRight, size: 20, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
