import 'package:http/http.dart' as http;

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
