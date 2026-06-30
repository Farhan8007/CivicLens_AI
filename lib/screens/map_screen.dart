import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/issue_model.dart';
import '../services/issue_service.dart';

class MapScreen extends StatefulWidget {
  final Future<List<IssueModel>> Function()? loadIssues;

  const MapScreen({super.key, this.loadIssues});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);
  static const MethodChannel _mapsDiagnosticsChannel = MethodChannel(
    'civiclens_ai/maps_diagnostics',
  );

  late Future<List<IssueModel>> _issuesFuture;
  GoogleMapController? _mapController;
  String? _lastFittedMarkerSignature;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _logRuntimeMapsApiKey();
    _issuesFuture = _loadIssues();
  }

  Future<void> _logRuntimeMapsApiKey() async {
    try {
      final metadata = await _mapsDiagnosticsChannel
          .invokeMapMethod<String, dynamic>('getMapsApiKeyMetadata');

      debugPrint(
        'MapScreen: Android package=${metadata?['packageName']}, '
        'maps metadata=${metadata?['metadataName']}, '
        'hasApiKey=${metadata?['hasApiKey']}, '
        'apiKey=${metadata?['apiKey']}',
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        'MapScreen: failed to read runtime Maps API key metadata: '
        '${error.code} ${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint(
        'MapScreen: failed to read runtime Maps API key metadata: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<List<IssueModel>> _loadIssues() async {
    debugPrint('MapScreen: loading issues from Firestore...');
    try {
      final issues = await (widget.loadIssues ?? IssueService().getAllIssues)();
      debugPrint('MapScreen: loaded ${issues.length} issue(s).');
      for (final issue in issues) {
        debugPrint(
          'MapScreen: issue "${issue.title}" '
          'lat=${issue.latitude}, lng=${issue.longitude}',
        );
      }
      return issues;
    } catch (error, stackTrace) {
      debugPrint('MapScreen: failed to load issues: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      _issuesFuture = _loadIssues();
    });
  }

  Future<void> _currentLocation() async {
    if (_mapController == null) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition();
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Filter Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _buildFilterOption('All'),
              _buildFilterOption('Pending'),
              _buildFilterOption('Resolved'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String filter) {
    final isSelected = _selectedFilter == filter;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(filter, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showIssueDetailsBottomSheet(IssueModel issue) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        issue.title.isEmpty ? 'Untitled report' : issue.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPriorityIndicator(issue.priority),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${issue.category.isEmpty ? 'Uncategorized' : issue.category} • ${_formatStatus(issue.status)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  issue.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityIndicator(String priority) {
    Color color;
    switch (priority.trim().toLowerCase()) {
      case 'high': color = Colors.red; break;
      case 'medium': color = Colors.orange; break;
      case 'low': color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildLegend() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Priority', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildLegendItem('High', Colors.red),
            const SizedBox(height: 6),
            _buildLegendItem('Medium', Colors.orange),
            const SizedBox(height: 6),
            _buildLegendItem('Low', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Map', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: FutureBuilder<List<IssueModel>>(
        future: _issuesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load issue locations.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allIssues = snapshot.data ?? const <IssueModel>[];
          final filteredIssues = allIssues.where((issue) {
            if (_selectedFilter == 'All') return true;
            final status = issue.status.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
            if (_selectedFilter == 'Pending' && status != 'pending') return false;
            if (_selectedFilter == 'Resolved' && status != 'resolved') return false;
            return true;
          }).toList();

          final markers = createIssueMarkers(
            filteredIssues,
            onMarkerTap: _showIssueDetailsBottomSheet,
          );
          
          debugPrint(
            'MapScreen: createIssueMarkers returned ${markers.length} marker(s).',
          );
          final initialCenter = markers.isEmpty
              ? _defaultCenter
              : markers.first.position;
          debugPrint(
            'MapScreen: initial camera target '
            'lat=${initialCenter.latitude}, lng=${initialCenter.longitude}',
          );

          _fitCameraToMarkersAfterBuild(markers);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialCenter,
                  zoom: markers.isEmpty ? 4.5 : 13,
                ),
                markers: markers,
                onMapCreated: (controller) {
                  debugPrint(
                    'MapScreen: GoogleMap created with '
                    '${markers.length} marker(s).',
                  );
                  _mapController = controller;
                  _fitCameraToMarkers(markers);
                },
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: true,
                zoomControlsEnabled: false,
              ),
              
              if (markers.isEmpty)
                const SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Card(
                      margin: EdgeInsets.all(16),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text('No reports match your filter.'),
                      ),
                    ),
                  ),
                ),
                
              // Legend
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(child: _buildLegend()),
              ),
              
              // Filter Button
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: FloatingActionButton.small(
                    heroTag: 'filterBtn',
                    onPressed: _showFilterMenu,
                    child: const Icon(Icons.filter_list),
                  ),
                ),
              ),

              // Current Location Button
              Positioned(
                bottom: 24,
                right: 16,
                child: SafeArea(
                  child: FloatingActionButton(
                    heroTag: 'locationBtn',
                    onPressed: _currentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _fitCameraToMarkersAfterBuild(Set<Marker> markers) {
    if (_mapController == null || markers.isEmpty) return;

    final markerSignature = _markerSignature(markers);
    if (_lastFittedMarkerSignature == markerSignature) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitCameraToMarkers(markers);
    });
  }

  Future<void> _fitCameraToMarkers(Set<Marker> markers) async {
    if (markers.isEmpty) return;

    final controller = _mapController;
    if (controller == null) {
      debugPrint('MapScreen: cannot fit camera before map controller exists.');
      return;
    }

    final markerSignature = _markerSignature(markers);
    if (_lastFittedMarkerSignature == markerSignature) return;

    try {
      if (markers.length == 1) {
        final marker = markers.single;
        debugPrint(
          'MapScreen: camera target '
          'lat=${marker.position.latitude}, lng=${marker.position.longitude}',
        );
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(marker.position, 15),
        );
      } else {
        final bounds = _boundsForMarkers(markers);
        if (_isSinglePointBounds(bounds)) {
          debugPrint(
            'MapScreen: camera target '
            'lat=${bounds.southwest.latitude}, '
            'lng=${bounds.southwest.longitude}',
          );
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(bounds.southwest, 15),
          );
        } else {
          final center = _centerOfBounds(bounds);
          debugPrint(
            'MapScreen: camera target bounds center '
            'lat=${center.latitude}, lng=${center.longitude}, '
            'southwest=${bounds.southwest.latitude},${bounds.southwest.longitude}, '
            'northeast=${bounds.northeast.latitude},${bounds.northeast.longitude}',
          );
          await controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 72),
          );
        }
      }
      _lastFittedMarkerSignature = markerSignature;
      debugPrint('MapScreen: camera fitted to ${markers.length} marker(s).');
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        'MapScreen: Google Maps platform error while fitting camera: '
        '${error.code} ${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint('MapScreen: failed to fit camera to markers: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

String _markerSignature(Set<Marker> markers) {
  final markerKeys =
      markers
          .map(
            (marker) =>
                '${marker.markerId.value}:'
                '${marker.position.latitude},${marker.position.longitude}',
          )
          .toList()
        ..sort();
  return markerKeys.join('|');
}

LatLngBounds _boundsForMarkers(Set<Marker> markers) {
  final firstPosition = markers.first.position;
  var south = firstPosition.latitude;
  var north = firstPosition.latitude;
  var west = firstPosition.longitude;
  var east = firstPosition.longitude;

  for (final marker in markers.skip(1)) {
    final position = marker.position;
    if (position.latitude < south) south = position.latitude;
    if (position.latitude > north) north = position.latitude;
    if (position.longitude < west) west = position.longitude;
    if (position.longitude > east) east = position.longitude;
  }

  return LatLngBounds(
    southwest: LatLng(south, west),
    northeast: LatLng(north, east),
  );
}

bool _isSinglePointBounds(LatLngBounds bounds) {
  return bounds.southwest.latitude == bounds.northeast.latitude &&
      bounds.southwest.longitude == bounds.northeast.longitude;
}

LatLng _centerOfBounds(LatLngBounds bounds) {
  return LatLng(
    (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
    (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
  );
}

@visibleForTesting
Set<Marker> createIssueMarkers(Iterable<IssueModel> issues, {void Function(IssueModel)? onMarkerTap}) {
  return issues
      .where(
        (issue) =>
            issue.latitude != null &&
            issue.longitude != null &&
            issue.latitude!.isFinite &&
            issue.longitude!.isFinite &&
            issue.latitude! >= -90 &&
            issue.latitude! <= 90 &&
            issue.longitude! >= -180 &&
            issue.longitude! <= 180,
      )
      .map(
        (issue) => Marker(
          markerId: MarkerId(issue.issueId),
          position: LatLng(issue.latitude!, issue.longitude!),
          icon: _getMarkerIcon(issue.priority),
          onTap: onMarkerTap != null ? () => onMarkerTap(issue) : null,
        ),
      )
      .toSet();
}

BitmapDescriptor _getMarkerIcon(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'high':
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    case 'medium':
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    case 'low':
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    default:
      return BitmapDescriptor.defaultMarker;
  }
}

String _formatStatus(String status) {
  final normalized = status.trim().toLowerCase().replaceAll(
    RegExp(r'[\s-]+'),
    '_',
  );
  if (normalized.isEmpty) return 'Unknown';

  return normalized
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
