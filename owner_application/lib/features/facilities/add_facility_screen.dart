import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:owner_application/core/utils/amenities_list.dart';
import 'package:owner_application/core/utils/indian_cities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFacilityScreen extends StatefulWidget {
  final Map<String, dynamic>? facility; // Null means Add Mode

  const AddFacilityScreen({super.key, this.facility});

  @override
  State<AddFacilityScreen> createState() => _AddFacilityScreenState();
}

class _AddFacilityScreenState extends State<AddFacilityScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController; // specific address part
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _rulesController;
  late TextEditingController _highlightTagController;

  // Selection & State
  String _selectedSport = 'Football';
  String _selectedCity = 'Mumbai'; // Dropdown selection
  String _selectedCancellationPolicy = 'Flexible'; // Default policy
  List<String> _selectedAmenities = []; // Tracks selected amenities

  bool _isLoading = false;
  final List<XFile> _newImages = []; // Newly picked images
  List<String> _existingImages = []; // Helper for Edit Mode
  final ImagePicker _picker = ImagePicker();

  // Operating Schedule
  int _slotDuration = 1; // hours
  List<bool> _operatingDays = List.filled(7, true); // Mon-Sun
  TimeOfDay _openingTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 23, minute: 0);
  final List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final List<String> _sports = [
    'Football',
    'Cricket',
    'Badminton',
    'Tennis',
    'Swimming',
    'Basketball',
    'Pickleball',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize Controllers
    _nameController = TextEditingController(text: widget.facility?['name']);

    // Parse Location (Assume format: "Address, City")
    String initialAddress = '';
    String initialCity = indianCities.first;

    if (widget.facility != null && widget.facility!['location'] != null) {
      final String fullLocation = widget.facility!['location'];
      final parts = fullLocation.split(', ');

      // Heuristic: Check if the last part is a known city
      if (parts.length > 1 && indianCities.contains(parts.last)) {
        initialCity = parts.last;
        initialAddress = parts.sublist(0, parts.length - 1).join(', ');
      } else {
        // Fallback: If city not found or format different, put everything in address
        // and default city to Mumbai (or try to match)
        initialAddress = fullLocation;
        // Try to find if any city name is in the string
        for (final city in indianCities) {
          if (fullLocation.contains(city)) {
            // Check if it's strictly at the end or standalone to avoid partial matches inside words
            // Simple approach: if it contains the city string, verify selection.
            initialCity = city;
            break;
          }
        }
      }

      // Safety: If Address became empty because Location was JUST "Mumbai", revert.
      if (initialAddress.trim().isEmpty) {
        initialAddress =
            fullLocation; // Put the whole thing back so user can fix it
      }
    }

    _addressController = TextEditingController(text: initialAddress);
    _selectedCity = initialCity;

    _priceController = TextEditingController(
      text: widget.facility != null
          ? widget.facility!['price_per_hour'].toString()
          : '',
    );
    _descriptionController = TextEditingController(
      text: widget.facility?['description'],
    );
    _rulesController = TextEditingController(text: widget.facility?['rules']);
    _highlightTagController = TextEditingController(
      text: widget.facility?['highlight_tag'],
    );

    if (widget.facility != null) {
      _selectedSport = widget.facility!['sport_type'] ?? 'Football';
      _selectedCancellationPolicy =
          widget.facility!['cancellation_policy'] ?? 'Flexible';

      if (widget.facility!['amenities'] != null) {
        _selectedAmenities = List<String>.from(widget.facility!['amenities']);
      }

      if (widget.facility!['images'] != null) {
        _existingImages = List<String>.from(widget.facility!['images']);
      } else if (widget.facility!['image_url'] != null) {
        _existingImages = [widget.facility!['image_url']];
      }
      // Load existing operating schedule
      if (widget.facility!['operating_schedule'] != null) {
        try {
          var scheduleData = widget.facility!['operating_schedule'];
          debugPrint('OWNER_APP_DEBUG: Raw schedule data: $scheduleData');
          debugPrint('OWNER_APP_DEBUG: Data Type: ${scheduleData.runtimeType}');

          Map<String, dynamic> schedule;

          if (scheduleData is String) {
            schedule = jsonDecode(scheduleData) as Map<String, dynamic>;
          } else if (scheduleData is Map) {
            schedule = Map<String, dynamic>.from(scheduleData);
          } else {
            debugPrint('Unknown schedule type: ${scheduleData.runtimeType}');
            return;
          }

          debugPrint('OWNER_APP_DEBUG: Parsed Schedule: $schedule');

          if (schedule['slot_duration'] != null) {
            _slotDuration = schedule['slot_duration'] is int
                ? schedule['slot_duration']
                : int.tryParse(schedule['slot_duration'].toString()) ?? 1;
          }

          if (schedule['operating_days'] != null &&
              schedule['operating_days'] is List) {
            _operatingDays = List<bool>.from(schedule['operating_days']);
            debugPrint(
              'OWNER_APP_DEBUG: Loaded Operating Days: $_operatingDays',
            );
          }

          if (schedule['opening_time'] != null) {
            try {
              final parts = (schedule['opening_time'] as String).split(':');
              _openingTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
              debugPrint('OWNER_APP_DEBUG: Loaded Opening Time: $_openingTime');
            } catch (e) {
              debugPrint('Error parsing opening_time: $e');
            }
          }

          if (schedule['closing_time'] != null) {
            try {
              final parts = (schedule['closing_time'] as String).split(':');
              _closingTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
              debugPrint('OWNER_APP_DEBUG: Loaded Closing Time: $_closingTime');
            } catch (e) {
              debugPrint('Error parsing closing_time: $e');
            }
          }
        } catch (e) {
          debugPrint('Error parsing schedule: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _highlightTagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_newImages.length + _existingImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 images allowed for optimal display.'),
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress slightly
      );

      if (image != null) {
        setState(() {
          _newImages.add(image);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages(String userId) async {
    List<String> urls = [];
    final storage = Supabase.instance.client.storage.from('facility_images');

    for (var image in _newImages) {
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${urls.length}.$fileExt';
      final filePath = '$userId/$fileName';

      await storage.uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      final imageUrl = storage.getPublicUrl(filePath);
      urls.add(imageUrl);
    }
    return urls;
  }

  Future<void> _submit() async {
    debugPrint('Submitting facility form...');
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check all fields (some might be empty)'),
        ),
      );
      return;
    }

    // Strict Validation: Price > 0
    final double? price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price strictly greater than 0.'),
        ),
      );
      return;
    }

    // Strict Validation: Description >= 50
    if (_descriptionController.text.trim().length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Description must be at least 50 characters long to provide enough detail for users.',
          ),
        ),
      );
      return;
    }

    // Strict Validation: Amenities >= 3
    if (_selectedAmenities.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least 3 amenities available at your venue.',
          ),
        ),
      );
      return;
    }

    debugPrint('Validation Success. Checking images...');
    if (_newImages.length + _existingImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide at least 3 images to showcase your facility.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'User not logged in';

      // 1. Upload New Images
      final newImageUrls = await _uploadImages(user.id);

      // 2. Combine All Images
      final allImages = [..._existingImages, ...newImageUrls];

      // 3. Prepare Full Location String
      final fullLocation = '${_addressController.text.trim()}, $_selectedCity';

      // 4. Prepare Data
      final updates = {
        'owner_id': user.id,
        'name': _nameController.text.trim(),
        'location': fullLocation,
        'sport_type': _selectedSport,
        'price_per_hour': double.parse(_priceController.text.trim()),
        'description': _descriptionController.text.trim(),
        'image_url': allImages.first, // Main display image
        'images': allImages, // Full gallery
        'amenities': _selectedAmenities,
        'rules': _rulesController.text.trim(),
        'cancellation_policy': _selectedCancellationPolicy,
        'highlight_tag': _highlightTagController.text.trim(),
        'operating_schedule': {
          'slot_duration': _slotDuration,
          'operating_days': _operatingDays,
          'opening_time':
              '${_openingTime.hour.toString().padLeft(2, '0')}:${_openingTime.minute.toString().padLeft(2, '0')}',
          'closing_time':
              '${_closingTime.hour.toString().padLeft(2, '0')}:${_closingTime.minute.toString().padLeft(2, '0')}',
        },
      };

      if (widget.facility == null) {
        // INSERT
        updates['rating'] = 5.0; // New listing starts strong!
        await Supabase.instance.client.from('facilities').insert(updates);
      } else {
        // UPDATE
        await Supabase.instance.client
            .from('facilities')
            .update(updates)
            .eq('id', widget.facility!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.facility == null
                  ? 'Facility created successfully! 🎉'
                  : 'Facility updated successfully! ✅',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving facility: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.facility != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Facility' : 'Add New Facility',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Section
              Text(
                'Facility Images (Min 3 REQUIRED)',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingImages.length + _newImages.length + 1,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                  itemBuilder: (ctx, index) {
                    if (index == _existingImages.length + _newImages.length) {
                      // Add Button
                      return GestureDetector(
                        onTap: _existingImages.length + _newImages.length < 5
                            ? _pickImage
                            : null,
                        child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_rounded,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Determine if it's an existing image or a new one
                    final isExisting = index < _existingImages.length;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: isExisting
                                  ? NetworkImage(_existingImages[index])
                                        as ImageProvider
                                  : FileImage(
                                      File(
                                        _newImages[index -
                                                _existingImages.length]
                                            .path,
                                      ),
                                    ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: GestureDetector(
                            onTap: () {
                              if (isExisting) {
                                _removeExistingImage(index);
                              } else {
                                _removeNewImage(index - _existingImages.length);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Name
              _buildLabel('Facility Name'),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g. Downtown Arena',
                icon: Icons.stadium_outlined,
              ),

              const SizedBox(height: 16),

              // Sport & Price Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Sport'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSport,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: _sports.map((sport) {
                                return DropdownMenuItem(
                                  value: sport,
                                  child: Text(
                                    sport,
                                    style: GoogleFonts.outfit(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedSport = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Price / Hour'),
                        _buildTextField(
                          controller: _priceController,
                          hint: '0.00',
                          icon: Icons.currency_rupee,
                          inputType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Address & City Section
              _buildLabel('City (Select from List)'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    menuMaxHeight: 300,
                    items: indianCities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(
                          city,
                          style: GoogleFonts.outfit(fontSize: 15),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCity = val!),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildLabel('Address (Street, Area, etc.)'),
              _buildTextField(
                controller: _addressController,
                hint: 'e.g. Plot No 12, Main Road',
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 16),

              // Description
              _buildLabel('Description (Min 50 chars)'),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Tell users about your turf...',
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // ─── Amenities Selection ───
              _buildLabel('Amenities (Min 3 required)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: amenitiesList.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity.name);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          amenity.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          amenity.name,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity.name);
                        } else {
                          _selectedAmenities.remove(amenity.name);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.blue.shade600,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.blue.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ─── Optional Customization Elements ───
              _buildLabel('Facility Rules (Optional)'),
              _buildTextField(
                controller: _rulesController,
                hint: 'e.g. Non-marking shoes only, No eating on pitch...',
                maxLines: 3,
                requiredField: false,
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Cancellation Policy'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCancellationPolicy,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: cancellationPolicies.map((policy) {
                                return DropdownMenuItem(
                                  value: policy,
                                  child: Text(
                                    policy,
                                    style: GoogleFonts.outfit(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(
                                () => _selectedCancellationPolicy = val!,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Highlight Tag (Optional)'),
                        _buildTextField(
                          controller: _highlightTagController,
                          hint: 'e.g. 20% OFF',
                          requiredField: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ─── Operating Schedule ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.schedule,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Operating Schedule',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Slot Duration
                    Text(
                      'Slot Duration',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [1, 2].map((dur) {
                        final isSelected = _slotDuration == dur;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _slotDuration = dur),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                '$dur Hour${dur > 1 ? 's' : ''}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Operating Days
                    Text(
                      'Operating Days',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(7, (i) {
                        final isActive = _operatingDays[i];
                        return GestureDetector(
                          onTap: () => setState(
                            () => _operatingDays[i] = !_operatingDays[i],
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.black : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive
                                    ? Colors.black
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              _dayNames[i],
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Opening / Closing Time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Opening Time',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _openingTime,
                                  );
                                  if (picked != null) {
                                    setState(() => _openingTime = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _openingTime.format(context),
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Closing Time',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _closingTime,
                                  );
                                  if (picked != null) {
                                    setState(() => _closingTime = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _closingTime.format(context),
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEdit ? 'Update Facility' : 'Create Facility',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? icon,
    TextInputType? inputType,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: inputType,
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      style: GoogleFonts.outfit(fontSize: 15, color: Colors.black87),
    );
  }
}
