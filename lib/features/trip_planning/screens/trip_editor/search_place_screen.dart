import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPlaceScreen extends StatefulWidget {
  const SearchPlaceScreen({super.key});

  @override
  State<SearchPlaceScreen> createState() => _SearchPlaceScreenState();
}

class _SearchPlaceScreenState extends State<SearchPlaceScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<dynamic> _places = [];

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
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=15');
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
        title: const Text('Search for a place'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., cafe, restaurant, park',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., phường Tân Phú, Quận 9',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _searchPlaces,
                    child: const Text('Search'),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                return ListTile(
                  title: Text(place['display_name']),
                  onTap: () {
                    Navigator.pop(context, place);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
