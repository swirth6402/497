import 'package:cloud_firestore/cloud_firestore.dart';
import 'medication.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Medication>> searchMedications(String query) async {
  List<Medication> results = [];
  try {
    // Get all documents from fdaData collection
    QuerySnapshot<Map<String, dynamic>> snapshot = 
        await _firestore.collection('fdaData').get();
    
    // Iterate through documents
    for (var doc in snapshot.docs) {
      try {
        // Access the openfda.generic_name field if it exists
        Map<String, dynamic> data = doc.data();
        if (data.containsKey('openfda') && 
            data['openfda'] != null && 
            data['openfda']['generic_name'] != null) {
          
          // The generic_name appears to be an array based on your screenshot
          List<dynamic> genericNames = data['openfda']['generic_name'];
          
          // Check if any generic name contains the search query
          for (var name in genericNames) {
            if (name.toString().toLowerCase().contains(query.toLowerCase())) {
              results.add(Medication.fromJson(data));
              break; // Only add this medication once
            }
          }
        }
      } catch (e) {
        print('Error processing document ${doc.id}: $e');
      }
    }
    
    return results;
  } catch (error) {
    print('Error searching medications: $error');
    rethrow;
  }
}
}
