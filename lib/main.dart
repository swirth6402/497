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
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InteractionChecker()),
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
  const InteractionChecker({super.key});

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
        ],
      ),
    );
  }
}