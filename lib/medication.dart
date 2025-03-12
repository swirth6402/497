class Medication {
  final String? brandName;
  final String genericName;
  final String? manufacturerName;
  final String id;
  final String activeIngredient;
  final String dosageAndAdministration;
  // Add other fields as needed

  Medication({
    required this.id,
    this.brandName,
    required this.genericName,
    this.manufacturerName,
    required this.activeIngredient,
    required this.dosageAndAdministration,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    // Extract generic name from openfda field
    String genericName = '';
    if (json['openfda'] != null && 
        json['openfda']['generic_name'] != null && 
        json['openfda']['generic_name'].isNotEmpty) {
      genericName = json['openfda']['generic_name'][0];
    }

    // You can set placeholders for now for fields you'll use later
    return Medication(
      id: json['id'] ?? json.hashCode.toString(), // Use document ID or generate one
      genericName: genericName,
      activeIngredient: genericName, // For now, use generic name as active ingredient too
      dosageAndAdministration: '', // Placeholder
    );
  }
}