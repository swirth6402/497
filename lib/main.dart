import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'medication.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'medmanage',
        theme: ThemeData(  // THIS IS WHERE THE THEME IS CREATED
          fontFamily: GoogleFonts.inter().fontFamily,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 118, 196, 255)
            
            ),
          textTheme: TextTheme(
            displayLarge: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: GoogleFonts.inter(

            )
          )
        ),
        home: const HomePage(), 
      ),
    );
  }
}


// *************************** HOME PAGE *********************************************
class HomePage extends StatefulWidget {
  const HomePage ({super.key});

  @override
  MyHomePage createState() => MyHomePage();
}

class MyHomePage extends State<HomePage> {
  final TextEditingController newItemController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [
         
          // Existing checklist
          Expanded(
            child: ListView.builder(
              itemCount: appState.items.length,
              itemBuilder: (context, index) {
                final item = appState.items[index];
                return CheckboxListTile(
                   title: Text(
                   item.medication.genericName, 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                  value: item.isChecked,
                  onChanged: (bool? value) {
                    appState.toggleChecked(item);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
              
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicationLookup()),
              );
            },
            child: const Text('Medication Lookup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DosageCalculatorPage()),
              );
            },
            child: const Text('Dosage checker'),
          ),
        ],
      ),
    );
  }
}
class MyAppState extends ChangeNotifier {
  // List of medications and their checked state
  List<Item> items = [];

  // Method to toggle the checked state
  void toggleChecked(Item item) {
    item.isChecked = !item.isChecked;
    notifyListeners();
  }

  // Method to add a new item to the list
  void addItem(Item item) {
    items.add(item);
    notifyListeners();
  }
}


// A class to represent each item in the list (word pair + checked state)
class Item {
  final Medication medication;
  bool isChecked;

  Item(this.medication, this.isChecked);
}

// ***************************** MEDICATION LOOKUP *********************************************

class MedicationLookup extends StatefulWidget {
  const MedicationLookup({super.key}); // This forwards the key to the StatefulWidget's constructor

  @override
  MyMedicationLookupState createState() => MyMedicationLookupState();
}

class MyMedicationLookupState extends State<MedicationLookup> {
  final TextEditingController newItemController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<Medication> _searchResults = []; // Use a private variable

  Future<List<Medication>> _searchMedications(String query) async {
    try {
      return await searchMedications(query);  //Call the searchMedications function from your api_service.dart file
    } catch (e) {
      print('Search error: $e');
      rethrow; // Re-throw the exception to be handled higher up
    }
  }

  @override
  
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final selectedItems = appState.items.where((item) => item.isChecked).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Lookup'),
      ),
      body: Column(
        children: [
          // Search Section (remains the same)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) { //This will trigger a rebuild when the text changes
                      setState(() {
                        //This will force a rebuild of the FutureBuilder
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search medications...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // No need for async here; FutureBuilder handles the async nature
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          // FutureBuilder to display search results based on the search query
          FutureBuilder<List<Medication>>(
            future: searchController.text.isEmpty
                ? Future.value([])
                : _searchMedications(searchController.text), //Only call the search function when text is not empty
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(); //Show loading indicator
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}'); //Handle errors
              } else {
                _searchResults = snapshot.data ?? []; // Update _searchResults
                final appState = context.watch<MyAppState>();
                return _searchResults.isEmpty
                    ? const SizedBox.shrink()
                    : Expanded( // Make it expandable
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final med = _searchResults[index];
                            return ListTile(
                              title: Text(med.genericName),
                              subtitle: Text(med.description),
                              trailing: ElevatedButton(
                                child: const Text('Add'),
                                onPressed: () {
                                  appState.addItem(Item(med, false));
                                },
                              ),
                            );
                          },
                        ),
                      );
              }
            },
          ),
          // Existing checklist
          Expanded(
            child: ListView.builder(
              itemCount: appState.items.length,
              itemBuilder: (context, index) {
                final item = appState.items[index];
                return CheckboxListTile(
                   title: Text(
                   item.medication.genericName, 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                  value: item.isChecked,
                  onChanged: (bool? value) {
                    appState.toggleChecked(item);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
              
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await syncFDAData();
            },
            child: const Text('Sync FDA Data'),
          ),
          if (selectedItems.length == 2)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InteractionChecker(selectedItems: selectedItems)),
                );
              },
              child: const Text('Interaction Checker'),
            ),
        ],
      ),
    );
  }
}


// ***************************** INTERACTION CHECKER *********************************
class InteractionChecker extends StatefulWidget {
  final List<Item> selectedItems;
  const InteractionChecker({super.key, required this.selectedItems});

  @override
  MyInteractionCheckerState createState() => MyInteractionCheckerState();
}

class MyInteractionCheckerState extends State<InteractionChecker> {
  final TextEditingController newItemController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<Medication> _searchResults = []; // Use a private variable

  Future<List<Medication>> _searchMedications(String query) async {
    try {
      return await searchMedications(query);  //Call the searchMedications function from your api_service.dart file
    } catch (e) {
      print('Search error: $e');
      rethrow; // Re-throw the exception to be handled higher up
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interaction Checker'),
      ),
      body: Column(
        
        children: [
          Text(
              'Selected Medications for Interaction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

          // checked items
          Expanded(
            child: widget.selectedItems.isEmpty
                ? const Center(
                    child: Text('No medications selected.'),
                  )
                : ListView.builder(
                    itemCount: widget.selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.selectedItems[index];
                      return ListTile(
                        title: Text(
                          item.medication.genericName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
              
              ],
            ),
          ),
          
          ElevatedButton(
            onPressed: () async {
              await syncFDAData();
            },
            child: const Text('Sync FDA Data'),
          ),
        ],
      ),
    );
  }
}
// ***************************** DOSAGE CALCULATOR *********************************

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Clark\'s Rule Dosage Calculator',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: DosageCalculatorPage(),
//     );
//   }
// }

class DosageCalculatorPage extends StatefulWidget {
  @override
  DosageCalculatorPageState createState() => DosageCalculatorPageState();
}

class DosageCalculatorPageState extends State<DosageCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _adultDosageController = TextEditingController();
  String _result = '';

  // Function to calculate dosage using Clark's rule
  void _calculateDosage() {
    final weight = double.tryParse(_weightController.text);
    final adultDosage = double.tryParse(_adultDosageController.text);

    if (weight != null && adultDosage != null && weight > 0 && adultDosage > 0) {
      // Clark's rule formula
      final dosage = (weight / 150) * adultDosage;
      setState(() {
        _result = 'The correct dosage for the child is: ${dosage.toStringAsFixed(2)} mg';
      });
    } else {
      setState(() {
        _result = 'Please enter valid weight(lb) and adult dosage(mg).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dosage Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the weight of the child in kg and the adult dosage in mg:',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              // Input for child weight
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Child\'s Weight (lb)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the child\'s weight.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              // Input for adult dosage
              TextFormField(
                controller: _adultDosageController,
                decoration: InputDecoration(
                  labelText: 'Adult Dosage (mg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the adult dosage.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              // Calculate button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _calculateDosage();
                  }
                },
                child: Text('Calculate Dosage'),
              ),
              SizedBox(height: 20),
              // Result display
              Text(
                _result,
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}