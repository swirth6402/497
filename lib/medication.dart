import 'child.dart';

class Medication {
  final String? brandName;
  final String genericName;
  final String? manufacturerName;
  final String id;
  final String activeIngredient;
  final String dosageAndAdministration;
  final String description;
  double? dosage;  
  Child? child; 
  bool isChecked;
  bool isRecurring; 
  // list representing days that medication is taken, 0 = sun, 1= mon, 2= tues, 3= wed, 4= thurs, 5= fri, 6=sat
  List<bool> daysUsed;
  
  // Add other fields as needed

  Medication({
    required this.id,
    this.brandName,
    this.dosage = 0,
    required this.genericName,
    this.manufacturerName,
    required this.activeIngredient,
    required this.dosageAndAdministration,
    this.isChecked = false,
    this.isRecurring = false,
    required this.description,
    this.child,
    List<bool>? daysUsed,
  }) : daysUsed = daysUsed ?? List.filled(7, false); 

  factory Medication.fromJson(Map<String, dynamic> json) {
    // Extract generic name from openfda field
    String genericName = '';
    String description = '';
    if (json['openfda'] != null && 
        json['openfda']['generic_name'] != null && 
        json['openfda']['generic_name'].isNotEmpty) {
      genericName = json['openfda']['generic_name'][0];
      
      if (json['indications_and_usage'] != null){
        description = json['indications_and_usage'][0];
      }
    }

    // You can set placeholders for now for fields you'll use later
    return Medication(
      id: json['id'] ?? json.hashCode.toString(), // Use document ID or generate one
      genericName: genericName,
      description: description,
      activeIngredient: genericName, // For now, use generic name as active ingredient too
      dosageAndAdministration: '', // Placeholder
    );
  }
}