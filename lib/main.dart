import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'medication.dart';
import 'child.dart';
import 'firebase_options.dart';
import 'days_selector.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';


// initalize list of children 
List<Child> children = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeNotifications((NotificationResponse response) {
    debugPrint('Notification tapped with payload: ${response.payload}');
    // add things here
  });
 
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
   DateTime _selectedDate = DateTime.now();

  void _showAddChildDialog(BuildContext context) {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();

  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => MedicationLookup()),
    );
}
 
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Add Child"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Child Name"),
            ),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(labelText: "Child Age"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: "Child Weight (lbs)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(

            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final age = int.tryParse(ageController.text);
              final weight = int.tryParse(weightController.text);
              if (name.isNotEmpty && age != null && weight != null) {
                setState(() {
                  children.add(
                    Child(childName: name, childAge: age, childWeight: weight),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

   
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: 
    
      Column( // u put scrollable content in columns 
        children: [
            EasyDateTimeLinePicker(
              focusedDate: _selectedDate,
              firstDate: DateTime(2024, 3, 18),
              lastDate: DateTime(2030, 3, 18),
              onDateChange: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
           Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                // Children 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Children",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ElevatedButton(
                      onPressed: () => _showAddChildDialog(context),
                      child: const Text("Add Child"),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                children.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("No children added yet."),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: children.length,
                        itemBuilder: (context, index) {
                          final child = children[index];
                          return ListTile(
                            title: Text(child.childName),
                            subtitle: Text(
                                "Age: ${child.childAge} | Weight: ${child.childWeight} lbs"),
                          );
                        },
                      ),
                const Divider(height: 32.0),
                // ********** Medication Checklist Section **********
                Text(
                      "Medications Needed  ${_selectedDate.month}/${_selectedDate.day} ",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appState.items.length,
                  itemBuilder: (context, index) {
                    final item = appState.items[index];
                    return CheckboxListTile(
                      title: Text(
                        item.medication.genericName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          item.medication.child != null
                          ? (item.medication.isRecurring
                              ? "${item.medication.child!.childName} - Recurring on ${recurringDaysText(item.medication.daysUsed)}"
                              : item.medication.child!.childName)
                          : "No child assigned",   
                      ),
                      value: item.isChecked,
                      onChanged: (bool? value) {
                        appState.toggleChecked(item);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        
          const Divider(height: 32.0),
    
        
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
          ElevatedButton(
            
            onPressed: () async {
              await showSimpleNotification();
            },
            child: const Text('Show Notification'),
          )
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

// helper function for recurring/days/etc 
String recurringDaysText(List<bool> days) {
  const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final selected = <String>[];
  for (int i = 0; i < days.length; i++) {
    if (days[i]) selected.add(dayLabels[i]);
  }
  return selected.isEmpty ? 'Not recurring' : selected.join(', ');
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
      return await searchMedications(query);  // calls the searchMedications function from the api_service.dart file
    } catch (e) {
      print('Search error: $e');
      rethrow; // Re-throw the exception to be handled higher up
    }
  }

  // This is the code for the pop up that prompts you to select a child for your medication
  Future<Map<String, dynamic>?> _showSelectChildDialog(BuildContext context) {
    List<bool> selectedDays = List.filled(7, false);
    Child? selectedChild;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Medication Settings"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select a Child:"),
                // Using a DropdownButton for child selection
                DropdownButton<Child>(
                  hint: const Text("Select a child"),
                  value: selectedChild,
                  onChanged: (Child? child) {
                    // Update selection and rebuild dialog UI
                    selectedChild = child;
                    (context as Element).markNeedsBuild();
                  },
                  items: children.map((child) {
                    return DropdownMenuItem<Child>(
                      value: child,
                      child: Text(child.childName),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text("Select Days of Use:"),
                DaysSelector(
                  selectedDays: selectedDays,
                  onChanged: (days) {
                    selectedDays = days;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                 // Return a map with the selected values. CHECK
                  Navigator.pop(context, {
                    'child': selectedChild,
                    'days': selectedDays,
                  });
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
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
          // Search Section
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
                            return ListTile (
                              title: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MedicationDescriptionPage(medication: med), // Pass the medication object
                                    ),
                                  );
                                },
                                child: Text(med.genericName),
                              ),
                              subtitle: Text(med.description),
                              trailing: TextButton(
                                child: const Text("Add"),
                                onPressed: () async {
                                  final result = await _showSelectChildDialog(context);
                                  if (result != null) {
                                    Child? child = result['child'];
                                    List<bool> days = result['days'];

                                    // Update your medication instance:
                                    med.child = child;
                                    med.daysUsed = days;

                                    // add to state CHECK
                                    appState.addItem(Item(med, false));
                                  }
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
                final med = item.medication;
                return CheckboxListTile(
                  title: GestureDetector( // Wrap Text in GestureDetector
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicationDescriptionPage(medication: med),
                      ),
                    );
                  },
                    child: Text(med.genericName),
                  ),
                  subtitle: Text(med.description),
                  value: item.isChecked, // Use the item's isChecked value
                  onChanged: (bool? value) {
                    appState.toggleChecked(item);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
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
  List<Medication> _searchResults = [];
  String _interactionResult = '';
  bool _isLoading = false; // Add a loading state variable

  Future<String> _checkInteractions(List<Item> selectedItems) async {
    setState(() {
      _isLoading = true; // Set loading to true when starting the request
      _interactionResult = ''; // Clear Previous result
    });
    if (selectedItems.length != 2) {
      setState(() {
        _isLoading = false; // Set loading to false if there's an error
        _interactionResult= 'Please select exactly two medications to check for interactions.';
      });
      return _interactionResult;
    }

    final apiKey = 'AIzaSyBVUMrM4mMygy7ogEskMJQUfkYTC6buA4g'; // Got this from: https://docs.flutter.dev/ai-toolkit Gemini AI configuration
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final medication1 = selectedItems[0].medication.genericName;
    final medication2 = selectedItems[1].medication.genericName;
    final prompt =
        'Is it safe to take $medication1 and $medication2 together? Reply yes or no';
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text ?? 'No response from AI.';

      setState(() {
      _interactionResult = result;
      _isLoading = false; // Hide loading indicator
      
    });
    return result;
    } catch (e) {
      setState(() {
        _interactionResult = 'Error checking interactions: $e';
        _isLoading = false;
      });
      return 'Error checking interactions: $e';
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
              if (widget.selectedItems.length == 2) // only show if 2 are selected.
                ElevatedButton(
                  onPressed: () async {
                    final result = await _checkInteractions(widget.selectedItems);
                    setState(() {
                      _interactionResult = result;
                    });
                  },
                  child: const Text('Check Interactions'),
                ),
              if (_isLoading) // Show loading indicator while checking
                const CircularProgressIndicator()
              else if (_interactionResult.isNotEmpty) // Show AI response
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        _interactionResult, // AI's response
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      if (_interactionResult.toLowerCase().contains("yes"))
                          Text("Compatible", style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold))
                      else if (_interactionResult.toLowerCase().contains("no"))
                          Text("Incompatible", style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
            ],
          ),
        ),
          
          ElevatedButton(
            onPressed: () async {
              await syncFDAData();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ensures the button is not stretched
              children: [
                const Text(
                  'Warning: Usage of AI in parsing openFDA data. '
                  'Results may not be up to date or may vary. Use with caution.',
                  style: TextStyle(fontSize: 12, color: Colors.red), // Smaller, red warning text
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5), // Adds spacing between the texts
                const Text(
                  'Sync FDA Data',
                  style: TextStyle(fontWeight: FontWeight.bold), // Makes it stand out
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ***************************** DOSAGE CALCULATOR *********************************


class DosageCalculatorPage extends StatefulWidget {
  @override
  DosageCalculatorPageState createState() => DosageCalculatorPageState();
}

class DosageCalculatorPageState extends State<DosageCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _adultDosageController = TextEditingController();
  String _result = '';
  Child? _selectedChild;

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
                'Select a child, or enter the weight of the child in pounds. Then, enter the adult dosage in mg:',
                style: TextStyle(fontSize: 18),
              ),
               Row(
                children: [
                  const Text("Select Child: "),
                  const SizedBox(width: 16.0),
                  DropdownButton<Child>(
                    hint: const Text("Select a child"),
                    value: _selectedChild,
                    items: children.map((child) {
                      return DropdownMenuItem<Child>(
                        value: child,
                        child: Text(child.childName),
                      );
                    }).toList(),
                    onChanged: (Child? child) {
                      setState(() {
                        _selectedChild = child;
                        if (child != null) {
                          _weightController.text =
                              child.childWeight.toString();
                        }
                      });
                    },
                  ),

                ],
              ),
            
              SizedBox(height: 20),
              // Input for child weight
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Child\'s Weight (lbs)',
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

// ***************************** MEDICATION DESCRIPTION (clickable via Medication LookUp) *********************************
  class MedicationDescriptionPage extends StatefulWidget {
    final Medication medication;
    const MedicationDescriptionPage({super.key, required this.medication});
    @override
    MedicationDescriptionState createState() => MedicationDescriptionState();
  }
  class MedicationDescriptionState extends State<MedicationDescriptionPage> {
 
 @override
   Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Description'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.medication.genericName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.medication.description,
              style: const TextStyle(fontSize: 16),
            ),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
 }
