import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app.dart';
import '../location.dart';
import '../models.dart';

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
  bool _checking = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingLocation = true;
      _loadError = null;
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
        _loadError = error.toString();
      });
    }
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _searchPlaces();
    });
  }

  Future<void> _searchPlaces() async {
    final location = _userLocation;
    if (location == null) {
      return;
    }
    setState(() {
      _searching = true;
      _loadError = null;
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
        if (_selected != null &&
            !places.any((place) => place.placeId == _selected!.placeId)) {
          _selected = null;
        }
      });
      await _fitToResults(places, location);
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error.toString());
        showApiError(context, error);
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

  Set<Marker> get _markers {
    return {
      for (final place in _places)
        Marker(
          markerId: MarkerId(place.placeId),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.address,
          ),
          onTap: () => setState(() => _selected = place),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _selected?.placeId == place.placeId
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueRed,
          ),
        ),
    };
  }

  Future<void> _confirmSelection() async {
    final selected = _selected;
    final location = _userLocation;
    if (selected == null) {
      showApiError(context, 'Select a restaurant on the map or from the list.');
      return;
    }
    final session = SessionScope.of(context);
    final router = GoRouter.of(context);
    setState(() => _checking = true);
    try {
      final verified = await session.verifyPlace(selected.placeId);
      session.rememberRestaurant(verified.toRecommendation());
      final error = await session.checkRestaurant(
        session.preferences.copyWith(
          restaurantName: verified.name,
          latitude: (location?.latitude ?? verified.latitude).toString(),
          longitude: (location?.longitude ?? verified.longitude).toString(),
        ),
      );
      if (!mounted) {
        return;
      }
      if (error != null && error.isNotEmpty) {
        showApiError(context, error);
      }
      router.push('/check-restaurant');
    } catch (error) {
      if (mounted) {
        showApiError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = _userLocation;

    return Scaffold(
      appBar: AppBar(title: const Text('Pick a restaurant')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Google Maps for an active restaurant near you, then confirm it.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _query,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: (_) => _searchPlaces(),
                      decoration: InputDecoration(
                        labelText: 'Search restaurants',
                        hintText: 'e.g. sushi, Sweetgreen, pizza',
                        suffixIcon: IconButton(
                          tooltip: 'Search',
                          onPressed: _searching ? null : _searchPlaces,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loadingLocation
                    ? const Center(child: CircularProgressIndicator())
                    : location == null
                        ? _ErrorPanel(
                            message: _loadError ??
                                'Location is required to show nearby restaurants.',
                            onRetry: _bootstrap,
                          )
                        : Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: location,
                                  zoom: 14,
                                ),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                markers: _markers,
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                  if (_places.isNotEmpty) {
                                    _fitToResults(_places, location);
                                  }
                                },
                                onTap: (_) => setState(() => _selected = null),
                              ),
                              if (_searching)
                                const Positioned(
                                  top: 12,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Card(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        child: Text('Searching Google Maps...'),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: _ResultsSheet(
                                  places: _places,
                                  selected: _selected,
                                  error: _loadError,
                                  onSelect: (place) {
                                    setState(() => _selected = place);
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(place.latitude, place.longitude),
                                        16,
                                      ),
                                    );
                                  },
                                  onConfirm: _checking ? null : _confirmSelection,
                                  confirming: _checking,
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
          if (_checking) const LoadingBarrier(message: 'Verifying restaurant...'),
        ],
      ),
    );
  }
}

class _ResultsSheet extends StatelessWidget {
  const _ResultsSheet({
    required this.places,
    required this.selected,
    required this.onSelect,
    required this.onConfirm,
    required this.confirming,
    this.error,
  });

  final List<MapPlace> places;
  final MapPlace? selected;
  final String? error;
  final ValueChanged<MapPlace> onSelect;
  final VoidCallback? onConfirm;
  final bool confirming;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              selected == null
                  ? (places.isEmpty
                      ? 'No active restaurants found nearby'
                      : '${places.length} restaurants nearby')
                  : selected!.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (selected != null) ...[
              const SizedBox(height: 4),
              Text(
                selected!.address.isEmpty
                    ? 'Address unavailable'
                    : selected!.address,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else if (error != null) ...[
              const SizedBox(height: 4),
              Text(
                error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            if (places.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    final isSelected = selected?.placeId == place.placeId;
                    return InkWell(
                      onTap: () => onSelect(place),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEEF6F0)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xFFE2D8C8),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              place.address.isEmpty
                                  ? 'Address unavailable'
                                  : place.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: selected == null || confirming ? null : onConfirm,
              child: Text(confirming ? 'Checking...' : 'Check this restaurant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
