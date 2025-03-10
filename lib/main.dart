import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';

void main() {
  runApp(MyApp());
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
        home: MyHomePage(),
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
}

// A class to represent each item in the list (word pair + checked state)
class Item {
  final WordPair wordPair;
  bool isChecked;

  Item(this.wordPair, this.isChecked);
}

class MyHomePage extends StatelessWidget {
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