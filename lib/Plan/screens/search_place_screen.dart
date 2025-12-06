import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPlaceScreen extends StatefulWidget {
  final String? prefilledLocation;
  final String? prefilledCategory;

  const SearchPlaceScreen({
    super.key,
    this.prefilledLocation,
    this.prefilledCategory,
  });

  @override
  State<SearchPlaceScreen> createState() => _SearchPlaceScreenState();
}

class _SearchPlaceScreenState extends State<SearchPlaceScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<dynamic> _places = [];

  @override
  void initState() {
    super.initState();
    // Auto-fill fields with prefilled data
    if (widget.prefilledLocation != null) {
      _locationController.text = widget.prefilledLocation!;
    }
    if (widget.prefilledCategory != null) {
      _categoryController.text = widget.prefilledCategory!;
    }

    // Auto-search if both fields are filled
    if (widget.prefilledLocation != null && widget.prefilledCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchPlaces();
      });
    }
  }

  Future<void> _searchPlaces() async {
    final category = _categoryController.text.trim();
    final location = _locationController.text.trim();
    String query;

    if (category.isNotEmpty && location.isNotEmpty) {
      query = '$category in $location';
    } else if (location.isNotEmpty) {
      query = location;
    } else if (category.isNotEmpty) {
      query = category;
    } else {
      setState(() {
        _places = [];
      });
      return;
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=15',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _places = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error searching for places: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Pick Activities'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Location field (auto-filled from destination)
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location (From Trip Destination)',
                    hintText: 'e.g., Hanoi, Ho Chi Minh City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: Colors.blue[600],
                    ),
                    filled: true,
                    fillColor: Colors.blue[50],
                  ),
                ),
                const SizedBox(height: 16),
                // Category field (auto-filled from activity type)
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category (From Activity Type)',
                    hintText: 'e.g., restaurant, hotel, attraction',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.orange[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.orange[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(Icons.category, color: Colors.orange[600]),
                    filled: true,
                    fillColor: Colors.orange[50],
                  ),
                ),
                const SizedBox(height: 20),
                // Search button with enhanced styling
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _searchPlaces,
                    child: const Text('Auto search'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _places.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No places found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching for places in your destination',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Icon(Icons.place, color: Colors.blue[600]),
                          ),
                          title: Text(
                            place['display_name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: place['type'] != null
                              ? Text(
                                  'Type: ${place['type']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          onTap: () {
                            Navigator.pop(context, {
                              'place': place,
                              'category': _categoryController.text.trim(),
                            });
                          },
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
