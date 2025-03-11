import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';

void main() {
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
  // List of word pairs and their checked state
  List<Item> items = List.generate(20, (index) {
    return Item(WordPair.random(), false);
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
  final WordPair wordPair;
  bool isChecked;

  Item(this.wordPair, this.isChecked);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key}); // This forwards the key to the StatefulWidget's constructor

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final TextEditingController newItemController = TextEditingController();
  WordPair? selectedWordPair;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkable List'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: appState.items.length,
              itemBuilder: (context, index) {
                final item = appState.items[index];
                return CheckboxListTile(
                  title: Text(item.wordPair.asLowerCase),
                  value: item.isChecked,
                  onChanged: (bool? value) {
                    // Toggle the checked state when user interacts with the checkbox
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
                DropdownButton<WordPair>(
                  hint: const Text('Select a WordPair'),
                  value: selectedWordPair,
                  items: List.generate(10, (index) {
                    return WordPair.random();
                  }).map((WordPair wordPair) {
                    return DropdownMenuItem<WordPair>(
                      value: wordPair,
                      child: Text(wordPair.asLowerCase),
                    );
                  }).toList(),
                  onChanged: (WordPair? newWordPair) {
                    setState(() {
                      selectedWordPair = newWordPair;
                    });
                  },
                ),

                // Button to add the selected word pair to the list
                ElevatedButton(
                  onPressed: () {
                    if (selectedWordPair != null) {
                      final newItem = Item(selectedWordPair!, false);
                      appState.addItem(newItem);
                      setState(() {
                        selectedWordPair = null; // Reset the dropdown after adding
                      });
                    }
                  },
                  child: const Text('Add New Item'),
                ),
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
