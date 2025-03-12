import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'medication.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // List of medications and their checked state
  List<Item> items = List.generate(3, (index) {
  final dummyMed = Medication(
    id: 'dummy-$index',
    genericName: 'defaultGeneric-$index', // Provide a default or generated generic name
    activeIngredient: WordPair.random().asLowerCase,
    dosageAndAdministration: '',
  );
  return Item(dummyMed, false);
});


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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key}); // This forwards the key to the StatefulWidget's constructor

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
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
        title: const Text('Medication List'),
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
                              title: Text(med.activeIngredient),
                              subtitle: Text(med.dosageAndAdministration),
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
                  title: Text(item.medication.genericName),
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
                // Dropdown menu to select a new word pair
                // DropdownButton<WordPair>(
                //   hint: const Text('Select a WordPair'),
                //   value: selectedWordPair,
                //   items: List.generate(10, (index) {
                //     return WordPair.random();
                //   }).map((WordPair wordPair) {
                //     return DropdownMenuItem<WordPair>(
                //       value: wordPair,
                //       child: Text(wordPair.asLowerCase),
                //     );
                //   }).toList(),
                //   onChanged: (WordPair? newWordPair) {
                //     setState(() {
                //       selectedWordPair = newWordPair;
                //     });
                //   },
                // ),
                // Button to add the selected word pair to the list
                // ElevatedButton(
                //   onPressed: () {
                //     if (selectedWordPair != null) {
                //       final newItem = Item(selectedWordPair!, false);
                //       appState.addItem(newItem);
                //       setState(() {
                //         selectedWordPair = null;
                //       });
                //     }
                //   },
                //   child: const Text('Add New Medication'),
                // ),
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
