import 'package:application/core/theme/app_colors.dart';
import 'package:application/core/utils/indian_cities.dart';
import 'package:application/core/utils/location_service.dart';
import 'package:application/core/widgets/location_search_sheet.dart';
import 'package:application/features/facilities/facility_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacilitiesScreen extends StatefulWidget {
  final String selectedCity;
  final ValueChanged<String> onCityChanged;
  final String? initialSport;

  const FacilitiesScreen({
    super.key,
    required this.selectedCity,
    required this.onCityChanged,
    this.initialSport,
  });

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  // Sort Options
  String _sortOption = 'Distance Nearest First';
  final List<String> _sortOptions = [
    'Price Low to High',
    'Price High to Low',
    'Rating High to Low',
    'Distance Nearest First',
    'Turf Height',
  ];

  // Filters
  final List<String> _selectedFilters = [];
  final List<String> _filterOptions = [
    'Cafe',
    'Covered',
    'Open 24*7',
    'Partnered',
    'Uncovered',
    'Football Friendly',
  ];

  // Distance
  double _maxDistance = 30.0;

  // Location & Sport
  String? _selectedSport;
  Position? _userPosition;

  bool _isLoading = true;
  List<Map<String, dynamic>> _facilities = [];
  List<Map<String, dynamic>> _filteredFacilities = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSport != null) {
      _selectedSport = widget.initialSport;
    }
    // We do NOT detect location on start anymore, we rely on parent's selectedCity.
    _fetchFacilities();
  }

  @override
  void didUpdateWidget(FacilitiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCity != oldWidget.selectedCity) {
      _fetchFacilities(); // Refresh if city changes externally
      _userPosition = null; // Clear GPS if city forced
    }
  }

  Future<void> _detectLocation() async {
    debugPrint('Starting location detection...');
    setState(() => _isLoading = true);
    final pos = await LocationService.getCurrentLocation();
    if (pos == null) debugPrint('Location detection returned null');
    if (pos != null) {
      debugPrint('Location found: ${pos.latitude}, ${pos.longitude}');
      final city = await LocationService.getCityFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      debugPrint('Detected city: $city');

      setState(() {
        _userPosition = pos;
        if (city != null) {
          if (indianCities.contains(city)) {
            // Update parent!
            widget.onCityChanged(city);
          }
        }
        _sortOption = 'Distance Nearest First';
      });
    }
    _fetchFacilities();
  }

  Future<void> _fetchFacilities() async {
    setState(() => _isLoading = true);
    try {
      // Basic Fetch
      var query = Supabase.instance.client.from('facilities').select();

      final response = await query;
      final data = List<Map<String, dynamic>>.from(response);

      _facilities = data;
      _applyFilters();
    } catch (e) {
      debugPrint('Error fetching facilities: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = List.from(_facilities);

    // 1. Filter by City
    if (_userPosition == null) {
      temp = temp
          .where((f) => (f['location'] as String).contains(widget.selectedCity))
          .toList();
    }

    // 1.5 Filter by Sport (if selected)
    if (_selectedSport != null) {
      temp = temp.where((f) {
        final sportType = f['sport_type'] as String?;
        if (sportType == null) return false;
        return sportType.toLowerCase() == _selectedSport!.toLowerCase();
      }).toList();
    }

    // 2. Filter by Attributes
    if (_selectedFilters.isNotEmpty) {
      temp = temp.where((f) {
        final amenities = List<String>.from(f['amenities'] ?? []);
        bool matches = true;
        for (var filter in _selectedFilters) {
          String lowerFilter = filter.toLowerCase();
          if (lowerFilter == 'partnered') {
            if (f['is_partnered'] != true) matches = false;
          } else if (lowerFilter == 'open 24*7') {
            if (f['open_24_7'] != true) matches = false;
          } else if (lowerFilter == 'cafe') {
            if (!amenities.contains('Cafe')) matches = false;
          } else if (lowerFilter == 'covered') {
            if (!amenities.contains('Covered')) matches = false;
          } else if (lowerFilter == 'uncovered') {
            if (amenities.contains('Covered')) matches = false;
          } else if (lowerFilter == 'football friendly') {
            if ((f['sport_type'] as String).toLowerCase() != 'football') {
              matches = false;
            }
          }
        }
        return matches;
      }).toList();
    }

    // 3. Filter by Distance & Attach Distance
    if (_userPosition != null) {
      for (var f in temp) {
        double? lat = f['lat'] != null ? (f['lat'] as num).toDouble() : null;
        double? lng = f['long'] != null ? (f['long'] as num).toDouble() : null;
        if (lat != null && lng != null) {
          f['distance_km'] = LocationService.calculateDistanceInKm(
            _userPosition!.latitude,
            _userPosition!.longitude,
            lat,
            lng,
          );
        } else {
          f['distance_km'] = 999.0; // Far away
        }
      }
      // Filter Max Distance
      temp = temp
          .where((f) => (f['distance_km'] as double) <= _maxDistance)
          .toList();
    }

    // 4. Sort
    temp.sort((a, b) {
      switch (_sortOption) {
        case 'Price Low to High':
          return (a['price_per_hour'] as num).compareTo(
            b['price_per_hour'] as num,
          );
        case 'Price High to Low':
          return (b['price_per_hour'] as num).compareTo(
            a['price_per_hour'] as num,
          );
        case 'Rating High to Low':
          return (b['rating'] as num).compareTo(a['rating'] as num);
        case 'Distance Nearest First':
          return (a['distance_km'] ?? 999).compareTo(b['distance_km'] ?? 999);
        case 'Turf Height':
          return (a['turf_height'] ?? '').compareTo(b['turf_height'] ?? '');
        default:
          return 0;
      }
    });

    setState(() {
      _filteredFacilities = temp;
    });
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._sortOptions.map(
                    (option) => RadioListTile<String>(
                      title: Text(
                        option.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      value: option,
                      groupValue: _sortOption,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _sortOption = val!);
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilters.contains(filter);
                      return FilterChip(
                        label: Text(filter.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              _selectedFilters.add(filter);
                            } else {
                              _selectedFilters.remove(filter);
                            }
                          });
                          setState(() {}); // Update parent
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Filter Turfs by Distance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Turfs within ${_maxDistance.toInt()} km:'),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 100,
                    divisions: 100,
                    label: '${_maxDistance.toInt()} km',
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setSheetState(() => _maxDistance = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return LocationSearchSheet(
          selectedCity: _userPosition == null ? widget.selectedCity : null,
          onCitySelected: (city) {
            widget.onCityChanged(city); // Update Parent
            setState(() {
              _userPosition = null;
            });
            Navigator.pop(context);
            // _fetchFacilities will be called by didUpdateWidget
          },
          onUseCurrentLocation: () async {
            Navigator.pop(context);
            await _detectLocation(); // This will update parent if city found
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showLocationSheet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 18,
                color: _userPosition != null
                    ? Colors.blue
                    : AppColors.textMain(context),
              ),
              const SizedBox(width: 4),
              Text(
                _userPosition != null
                    ? 'Current Location'
                    : widget.selectedCity,
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSortSheet,
                    icon: const Icon(Icons.sort, size: 16),
                    label: const Text('Sort'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMain(context),
                      side: BorderSide(color: AppColors.divider(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterSheet,
                    icon: const Icon(Icons.filter_list, size: 16),
                    label: const Text('Filters'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMain(context),
                      side: BorderSide(color: AppColors.divider(context)),
                      backgroundColor: _selectedFilters.isNotEmpty
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFacilities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: AppColors.divider(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No turfs found in ${_userPosition != null ? 'range' : widget.selectedCity}',
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilters.clear();
                              _maxDistance = 100;
                            });
                            _fetchFacilities();
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75, // Taller for tags
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _filteredFacilities.length,
                    itemBuilder: (context, index) {
                      final facility = _filteredFacilities[index];
                      final name = facility['name'];
                      final price = facility['price_per_hour'];
                      final imageUrl = facility['image_url'];
                      final distance = facility['distance_km'];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FacilityDetailsScreen(facility: facility),
                            ),
                          );
                        },
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1.2,
                                    child: imageUrl != null
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                                  color: AppColors.subtleBg(
                                                    context,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            color: AppColors.subtleBg(context),
                                          ),
                                  ),
                                  if (facility['is_partnered'] == true)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'PARTNER',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (distance != null && distance < 900)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.near_me,
                                            size: 12,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${distance.toStringAsFixed(1)} km',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 4),
                                    Text(
                                      '₹$price / hr',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
