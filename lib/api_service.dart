import 'package:http/http.dart' as http;
import 'dart:convert';
import 'medication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart'; // Import the new service

final FirebaseService _firebaseService = FirebaseService(); //Create an instance of the firebase service


Future<void> syncFDAData() async {
  final url = 'http://127.0.0.1:5001/medmanage-451913/us-central1/syncFDAData';
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print('Sync successful: ${response.body}');
    } else {
      print('Sync failed: ${response.statusCode}');
    }
  } catch (error) {
    print('Error calling Cloud Function: $error');
  }
}

Future<List<Medication>> searchMedications(String query) async {
  return await _firebaseService.searchMedications(query); // Use the service method
}