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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        title: 'medchecker',
        theme: ThemeData(
          // THIS IS WHERE THE THEME IS CREATED
          useMaterial3: true,
          fontFamily: GoogleFonts.inter().fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF76C4FF),
            brightness: Brightness.light,
          ),
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: Colors.black54, width: 1.5),
            fillColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF008000); // ✅ green when checked
              }
              return Colors.white; // ❎ white when unchecked
            }),
            checkColor: MaterialStateProperty.all(
              Colors.white,
            ), // ✅ white checkmark
          ),

          textTheme: GoogleFonts.interTextTheme().copyWith(
            displayLarge: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            bodyMedium: const TextStyle(fontSize: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFFF0F4F8),
          ),
        ),
        home: const MainPageView(),
      ),
    );
  }
}

// *********************** PageView Controller *******************************************
// added this to make pages swipable/more easily navigatable
class MainPageView extends StatefulWidget {
  const MainPageView({super.key});

  @override
  MainPageViewState createState() => MainPageViewState();
}

class MainPageViewState extends State<MainPageView> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPageIndex = 0;

  final List<Widget> _pages = [
    DosageCalculatorPage(),
    const HomePage(),
    const MedicationLookup(),
    InteractionChecker(),
  ];

  final List<String> _pageTitles = [
    'Dosage Calculator',
    'Home',
    'Medication Lookup',
    'Interaction Checker',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitles[_currentPageIndex])),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentPageIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Dosage'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Interactions',
          ),
        ],
      ),
    );
  }
}

// *************************** HOME PAGE *********************************************
class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

    void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse,
    ) async {
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
              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Child Age"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: "Child Weight (lbs)",
                ),
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
                      Child(
                        childName: name,
                        childAge: age,
                        childWeight: weight,
                      ),
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
    final filteredItems =
        appState.items
            .where((item) => item.isScheduledForDate(_selectedDate))
            .toList();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            EasyDateTimeLine(
              initialDate: _selectedDate,
              onDateChange: (selectedDate) {
                setState(() {
                  _selectedDate = selectedDate;
                });
              },
              activeColor: const Color(0xFFFFC0CB), // Pink for selected day
              dayProps: const EasyDayProps(
                height: 70,
                width: 55,
                dayStructure: DayStructure.dayStrDayNum,
                // backgroundColor: Color(0xFFADD8E6), // Light blue for all days
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
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
                              "Age: ${child.childAge} | Weight: ${child.childWeight} lbs",
                            ),
                          );
                        },
                      ),
                  const Divider(height: 32.0),
                  // ********** Medication Checklist Section **********
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      "Medications Needed  ${_selectedDate.month}/${_selectedDate.day} ",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),

                  filteredItems.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text("No medications scheduled for this day."),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Card(
                            color: const Color(0xFFADD8E6),
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              MedicationDescriptionPage(
                                                medication: item.medication,
                                              ),
                                    ),
                                  );
                                },
                                child: Text(
                                  item.medication.genericName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),

                              subtitle: Text(
                                (item.medication.child != null)
                                    ? (item.medication.isRecurring
                                        ? "${item.medication.child!.childName} - Recurring on ${recurringDaysText(item.medication.daysUsed)}"
                                        : item.medication.child!.childName)
                                    : "No child assigned",
                              ),
                              value: item.isChecked,
                              onChanged: (bool? value) {
                                appState.toggleChecked(item);
                              },
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
            const Divider(height: 32.0),
            ElevatedButton(
              onPressed: () async {
                await showSimpleNotification();
              },
              child: const Text('Show Notification'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // List of medications and their checked state
  List<Item> items = [];
  List<Item> interactionItems = [];

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

  // interaction check helper functions
  void addToInteractionCheck(Item item) {
    if (!interactionItems.contains(item)) {
      if (interactionItems.length >= 2) {
        // If we already have 2 items, remove the first one
        interactionItems.removeAt(0);
      }
      interactionItems.add(item);
      notifyListeners();
    }
  }

  void removeFromInteractionCheck(Item item) {
    interactionItems.remove(item);
    notifyListeners();
  }

  void clearInteractionCheck() {
    interactionItems.clear();
    notifyListeners();
  }

  void updateMedicationDosage(Medication medication, double dosage) {
    // Find the item that contains this medication
    for (var item in items) {
      if (item.medication == medication) {
        item.medication.dosage = dosage;
        notifyListeners(); // Notify listeners to rebuild UI
        break;
      }
    }
  }
}

// A class to represent each item in the list (word pair + checked state)
class Item {
  final Medication medication;
  bool isChecked;

  Item(this.medication, this.isChecked);
  bool isScheduledForDate(DateTime date) {
    // If it is recurring, check if it's scheduled for the day of the week
    final dayIndex = date.weekday % 7; // Convert to 0-6 range where 0 is Sunday
    return medication.daysUsed[dayIndex];
  }
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
  const MedicationLookup({super.key});

  @override
  MyMedicationLookupState createState() => MyMedicationLookupState();
}

class MyMedicationLookupState extends State<MedicationLookup> {
  final TextEditingController newItemController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<Medication> _searchResults = [];

  Future<List<Medication>> _searchMedications(String query) async {
    try {
      return await searchMedications(query);
    } catch (e) {
      print('Search error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _showSelectChildDialog(BuildContext context) {
    List<bool> selectedDays = List.filled(7, false);
    Child? selectedChild;
    bool selectedIsRecurring = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Medication Settings"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select a Child:"),
                    DropdownButton<Child>(
                      hint: const Text("Select a child"),
                      value: selectedChild,
                      onChanged: (Child? child) {
                        setState(() {
                          selectedChild = child;
                        });
                      },
                      items:
                          children.map((child) {
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
                        setState(() {
                          selectedDays = days;
                        });
                      },
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: selectedIsRecurring,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedIsRecurring = value ?? false;
                            });
                          },
                        ),
                        const Text("Recurring"),
                      ],
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
                    Navigator.pop(context, {
                      'child': selectedChild,
                      'days': selectedDays,
                      'isRecurring': selectedIsRecurring,
                    });
                  },
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final selectedItems =
        appState.items.where((item) => item.isChecked).toList();

    return Scaffold(
      body: SingleChildScrollView(
        // Added SingleChildScrollView here
        child: Column(
          children: [
            // Search Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search medications...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            // FutureBuilder to display search results based on the search query
            FutureBuilder<List<Medication>>(
              future:
                  searchController.text.isEmpty
                      ? Future.value([])
                      : _searchMedications(searchController.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  _searchResults = snapshot.data ?? [];
                  return _searchResults.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final med = _searchResults[index];
                          return ListTile(
                            title: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MedicationDescriptionPage(
                                          medication: med,
                                        ),
                                  ),
                                );
                              },
                              child: Text(med.genericName),
                            ),
                            subtitle: Text(med.description),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.compare_arrows,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Add to Interaction Checker',
                                  onPressed: () {
                                    Item newItem = Item(med, false);
                                    appState.addToInteractionCheck(newItem);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${med.genericName} added to interaction checker',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                                TextButton(
                                  child: const Text("Add"),
                                  onPressed: () async {
                                    final result = await _showSelectChildDialog(
                                      context,
                                    );
                                    if (result != null) {
                                      Child? child = result['child'];
                                      List<bool> days = result['days'];
                                      bool isRecurring = result['isRecurring'];

                                      med.child = child;
                                      med.daysUsed = days;
                                      med.isRecurring = isRecurring;

                                      appState.addItem(Item(med, false));
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: []),
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
                    MaterialPageRoute(
                      builder:
                          (context) => InteractionChecker(
                            selectedInteraction: selectedItems,
                          ),
                    ),
                  );
                },
                child: const Text('Interaction Checker'),
              ),
          ],
        ),
      ),
    );
  }
}

// ***************************** INTERACTION CHECKER *********************************
class InteractionChecker extends StatefulWidget {
  final List<Item>? selectedInteraction;
  InteractionChecker({super.key, this.selectedInteraction});

  @override
  MyInteractionCheckerState createState() => MyInteractionCheckerState();
}

class MyInteractionCheckerState extends State<InteractionChecker> {
  final TextEditingController newItemController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<Medication> _searchResults = [];
  late List<Item> _selectedItems;
  String _interactionResult = '';
  bool _isLoading = false; // Add a loading state variable

  // logic for adding items to interaction checker
  @override
  void initState() {
    super.initState();
    final appState = Provider.of<MyAppState>(context, listen: false);
    _selectedItems =
        widget.selectedInteraction ?? List.from(appState.interactionItems);
  }

  // interaction checker helper function
  Future<String> _checkInteractions(List<Item> selectedItems) async {
    setState(() {
      _isLoading = true; // Set loading to true when starting the request
      _interactionResult = ''; // Clear Previous result
    });
    if (selectedItems.length != 2) {
      setState(() {
        _isLoading = false; // Set loading to false if there's an error
        _interactionResult =
            'Please select exactly two medications to check for interactions.';
      });
      return _interactionResult;
    }

    final apiKey =
        'AIzaSyBVUMrM4mMygy7ogEskMJQUfkYTC6buA4g'; // Got this from: https://docs.flutter.dev/ai-toolkit Gemini AI configuration
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
    // Use items from appState.interactionItems if available
    List<Item> displayItems =
        appState.interactionItems.isNotEmpty
            ? appState.interactionItems
            : _selectedItems;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Select two medications from your list or add from search to check for potential interactions.',
              style: TextStyle(fontSize: 16),
            ),
          ),

          const Divider(height: 32.0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Medications:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                displayItems.isEmpty
                    ? const Text(
                      'No medications selected. Add medications using the compare button or from your list below.',
                    )
                    : Wrap(
                      spacing: 8.0,
                      children:
                          displayItems.map((item) {
                            return Chip(
                              label: Text(item.medication.genericName),
                              onDeleted: () {
                                appState.removeFromInteractionCheck(item);
                                setState(() {
                                  _selectedItems.remove(item);
                                });
                              },
                            );
                          }).toList(),
                    ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (displayItems.length < 2)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Add From Your Medications:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: appState.items.length,
                      itemBuilder: (context, index) {
                        final item = appState.items[index];
                        bool isSelected = displayItems.contains(item);

                        return ListTile(
                          title: Text(item.medication.genericName),
                          subtitle: Text(item.medication.description),
                          trailing: IconButton(
                            icon: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: isSelected ? Colors.green : Colors.blue,
                            ),
                            onPressed:
                                isSelected
                                    ? () {
                                      appState.removeFromInteractionCheck(item);
                                      setState(() {
                                        _selectedItems.remove(item);
                                      });
                                    }
                                    : () {
                                      appState.addToInteractionCheck(item);
                                      setState(() {
                                        _selectedItems.add(item);
                                      });
                                    },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          if (displayItems.length == 2)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await _checkInteractions(displayItems);
                  setState(() {
                    _interactionResult = result;
                  });
                },
                child: const Text('Check Interactions'),
              ),
            ),

          if (_isLoading)
            const CircularProgressIndicator()
          else if (_interactionResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
              child: Column(
                children: [
                  Text(
                    _interactionResult,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (_interactionResult.toLowerCase().contains("yes"))
                    Text(
                      "Compatible",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (_interactionResult.toLowerCase().contains("no"))
                    Text(
                      "Incompatible",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Warning: Usage of AI in parsing openFDA data. '
              'Results may not be up to date or may vary. Use with caution.',
              style: TextStyle(fontSize: 12, color: Colors.red),
              textAlign: TextAlign.center,
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
  Medication? _selectedMedication;

  // Function to calculate dosage using Clark's rule
  void _calculateDosage() {
    final weight = double.tryParse(_weightController.text);
    final adultDosage = double.tryParse(_adultDosageController.text);

    if (weight != null &&
        adultDosage != null &&
        weight > 0 &&
        adultDosage > 0) {
      final dosage = (weight / 150) * adultDosage;
      setState(() {
        _result =
            'The correct dosage for the child is: ${dosage.toStringAsFixed(2)} mg';
      });
      if (_selectedMedication != null) {
        // Get app state and update the medication
        var appState = Provider.of<MyAppState>(context, listen: false);
        appState.updateMedicationDosage(_selectedMedication!, dosage);

        setState(() {
          _result += '\nDosage saved to ${_selectedMedication!.genericName}';
        });
      }
    } else {
      setState(() {
        _result = 'Please enter valid weight (lbs) and adult dosage(mg).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    List<Medication> medications =
        appState.items.map((item) => item.medication).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Use ListView for scrollability on small screens
            children: [
              Text(
                'Select a child, or enter the weight of the child in pounds. Then, enter the adult dosage in mg:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Child Dropdown
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Select Child (Optional)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: DropdownButton<Child>(
                      hint: const Text("Select a child"),
                      value: _selectedChild,
                      isExpanded: true,
                      items:
                          children.map((child) {
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
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Medication Dropdown (Optional)
              Text(
                "Select Medication to Save Dosage (Optional):",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<Medication>(
                hint: const Text("Select a Medication"),
                value: _selectedMedication,
                isExpanded: true,
                items:
                    medications.isEmpty
                        ? [
                          DropdownMenuItem<Medication>(
                            value: null,
                            child: Text("No medications available"),
                          ),
                        ]
                        : medications.map((medication) {
                          return DropdownMenuItem<Medication>(
                            value: medication,
                            child: Text(medication.genericName),
                          );
                        }).toList(),
                onChanged:
                    medications.isEmpty
                        ? null
                        : (Medication? medication) {
                          setState(() {
                            _selectedMedication = medication;
                          });
                        },
              ),

              const SizedBox(height: 20),

              // Child Weight Input
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

              const SizedBox(height: 20),

              // Adult Dosage Input
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

              const SizedBox(height: 20),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _calculateDosage();
                  }
                },
                child: Text('Calculate Dosage'),
              ),

              const SizedBox(height: 20),

              // Result
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
  String _aiGeneratedDescription = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateDescription();
  }

  Future<void> _generateDescription() async {
    setState(() {
      _isLoading = true;
      _aiGeneratedDescription = '';
    });

    final apiKey = 'AIzaSyBYOnoU40by4erAfWuRbPezXIVR_pCHQBM';
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt =
        'Describe the medication ${widget.medication.genericName} for users in a paragraph. 50 words';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text ?? 'No description generated.';

      setState(() {
        _aiGeneratedDescription = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiGeneratedDescription = 'Error generating description: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Description')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.medication.genericName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(
                _aiGeneratedDescription.isNotEmpty
                    ? _aiGeneratedDescription
                    : widget
                        .medication
                        .description, // Fallback to provided description
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            const Text(
              'Warning: AI generated descriptions may not be accurate. '
              'Use with caution.',
              style: TextStyle(fontSize: 12, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
}
