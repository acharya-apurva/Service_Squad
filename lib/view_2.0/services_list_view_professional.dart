import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_squad/controller/professional_service_controller.dart';
import 'package:service_squad/view/reviews_list_view.dart';
import 'package:service_squad/view/service_entry_view.dart';
import '../controller/profile_controller.dart';
import '../model/professional_service.dart';

class ProfessionalListServicesView extends StatefulWidget {
  ProfessionalListServicesView({Key? key}) : super(key: key);
  bool isDark = false;
  String categoryToPopulate = '';

  ProfessionalListServicesView.WithPersistedThemeAndCategory(
      bool inheritedIsDark, String categoryName) {
    isDark = inheritedIsDark;
    categoryToPopulate = categoryName;
  }

  @override
  State<ProfessionalListServicesView> createState() =>
      _ProfessionalListServicesViewState.withPersistedThemeAndCategory(
          isDark, categoryToPopulate);
}

class _ProfessionalListServicesViewState
    extends State<ProfessionalListServicesView> {
  final ProfessionalServiceController professionalServiceController =
      ProfessionalServiceController();
  String? selectedCategory;
  bool isDark;
  List<ProfessionalService> filteredEntries = [];
  final TextEditingController searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String categoryName;
  XFile? _image;

  _ProfessionalListServicesViewState.withPersistedThemeAndCategory(
      this.isDark, this.categoryName);

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  void _showEditDialog(BuildContext context,
      ProfessionalService professionalServiceEntry, int index) {
    TextEditingController descriptionEditingController =
        TextEditingController();
    descriptionEditingController.text = professionalServiceEntry
        .serviceDescription; // Initialize the text field with existing content.

    TextEditingController wageEditingController = TextEditingController();
    wageEditingController.text = '${professionalServiceEntry!.wage}';

    ProfessionalServiceController professionalServiceController =
        ProfessionalServiceController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Diary Entry'),
          content: Column(children: [
            TextField(
              controller: descriptionEditingController,
              decoration: InputDecoration(labelText: "New Description"),
              maxLines: null, // Allows multiple lines of text.
            ),
            TextField(
              controller: wageEditingController,
              decoration: InputDecoration(labelText: "New Wage"),
              maxLines: null, // Allows multiple lines of text.
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _pickImageFromGallery(),
              child: Text('pick image from gallery'),
            )
          ]),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                print(
                    'professionalServiceEntrycategory is: ${professionalServiceEntry!.category}');
                // Save the edited content to the service entry.
                String location = await ProfileController()
                    .getUserLocation(FirebaseAuth.instance.currentUser!.uid);
                await professionalServiceController.updateProfessionalService(
                    ProfessionalService(
                        serviceDescription: descriptionEditingController.text,
                        wage: double.parse(wageEditingController.text),
                        category: professionalServiceEntry.category,
                        id: professionalServiceEntry!.id,
                        rating: professionalServiceEntry.rating,
                        location: location,
                        email: professionalServiceEntry.email,
                        technicianAlias:
                            professionalServiceEntry.technicianAlias,
                        imagePath: professionalServiceEntry.imagePath,
                        reviewList: professionalServiceEntry.reviewList,
                        reviewsMap: professionalServiceEntry.reviewsMap));

                updateState(professionalServiceEntry.category);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Center(child: Text('Entry successfully saved!')),
                      backgroundColor: Colors.deepPurple),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void applySearchBarLocationCategoryRatingBasedQueryAndUpdateState3(
      bool isOnSubmitted) async {
    List<String> categories = [
      "Snow Clearance",
      "House Keeping",
      "Handy Services",
      "Lawn Mowing"
    ];

    final serviceEntries = selectedCategory != null
        ? await professionalServiceController
            .getProfessionalServices(selectedCategory!)
            .first
        : await professionalServiceController
            .getAllProfessionalServices()
            .first;
    print('length of serviceEntries is ${serviceEntries.length}');
    // final serviceEntries = await professionalServiceController
    //     .getAllAvailableProfessionalServiceCollections()
    //     .first;
    String userLocation = await ProfileController()
        .getUserLocation(FirebaseAuth.instance.currentUser!.uid);
    bool isSnackBarDisplayed = false;

    setState(() {
      // Initialize filteredEntries with a copy of serviceEntries
      filteredEntries = List<ProfessionalService>.from(serviceEntries);
      List<int> ratings = [1, 2, 3, 4, 5];
      String queryText = searchController.text.toLowerCase();

      print(
          '!categories.contains(queryText): ${!categories.contains(queryText)}');
      if (!categories.contains(queryText) &&
          !ratings.contains(int.tryParse(queryText))) {
      }

      print('queryText: $queryText');
      print(
          'categories.contains(queryText): ${categories.contains(queryText)}');
      print(
          'ratings.contains(int.tryParse(queryText)): ${ratings.contains(int.tryParse(queryText))}');
      // Filter based on the rating or category
      if (searchController.text.isNotEmpty) {
        filteredEntries = filteredEntries.where((entry) {
          print('entry.location.toLowerCase() is ${userLocation}');
          return entry.category
                  .toLowerCase()
                  .contains(queryText.toLowerCase()) ||
              entry.rating == int.tryParse(queryText) ||
              entry.location.contains(queryText.toLowerCase());
        }).toList();
      } else if (selectedCategory != null) {
        filteredEntries = filteredEntries.where((entry) {
          return entry.category == selectedCategory;
        }).toList();
      }

      // Show a message if no matches are found
      print('filteredEntries.length: ${filteredEntries.length}');
      print('serviceEntries.length: ${serviceEntries.length}');

      if (isOnSubmitted &&
          searchController.text.isNotEmpty &&
          !isSnackBarDisplayed &&
          (filteredEntries.length == serviceEntries.length ||
              filteredEntries.length == 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Center(
                  child: Text('No match found!',
                      style: TextStyle(
                        color: Colors.white, // Customize the hint text color
                        fontSize: 12, // Customize the hint text font size
                      ))),
              backgroundColor: Colors.deepPurple),
        );
      }
      isSnackBarDisplayed = true;
    });
  }

  void applySearchBarLocationBasedQueryAndUpdateState(
      bool isOnSubmitted) async {
    List<String> categories = [
      "Snow Clearance",
      "House Keeping",
      "Handy Services",
      "Lawn Mowing"
    ];

    final serviceEntries = selectedCategory != null
        ? await professionalServiceController
            .getProfessionalServices(selectedCategory!)
            .first
        : await professionalServiceController
            .getAllProfessionalServices()
            .first;
    print('length of serviceEntries is ${serviceEntries.length}');

    String userLocation = await ProfileController()
        .getUserLocation(FirebaseAuth.instance.currentUser!.uid);
    bool isSnackBarDisplayed = false;

    setState(() {
      // Initialize filteredEntries with a copy of serviceEntries
      filteredEntries = List<ProfessionalService>.from(serviceEntries);
      List<int> ratings = [1, 2, 3, 4, 5];
      String queryText = searchController.text.toLowerCase();
      bool queryIsLocation = false;

      print(
          '!categories.contains(queryText): ${!categories.contains(queryText)}');
      if (!categories.contains(queryText) &&
          !ratings.contains(int.tryParse(queryText))) {
        queryIsLocation = true;
      }

      print('queryText: $queryText');
      print(
          'categories.contains(queryText): ${categories.contains(queryText)}');
      print(
          'ratings.contains(int.tryParse(queryText)): ${ratings.contains(int.tryParse(queryText))}');
      // Filter based on the rating or category
      if (searchController.text.isNotEmpty) {
        filteredEntries = filteredEntries.where((entry) {
          print('entry.location.toLowerCase() is ${userLocation}');
          return entry.location.contains(queryText.toLowerCase());
        }).toList();
      }
      if (selectedCategory != null) {
        filteredEntries = filteredEntries.where((entry) {
          return entry.category == selectedCategory;
        }).toList();
      }

      // Show a message if no matches are found
      print('filteredEntries.length: ${filteredEntries.length}');
      print('serviceEntries.length: ${serviceEntries.length}');

      if (isOnSubmitted &&
          searchController.text.isNotEmpty &&
          !isSnackBarDisplayed &&
          (filteredEntries.length == serviceEntries.length ||
              filteredEntries.length == 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text('No match found!')),
            duration: Duration(milliseconds: 1000),
          ),
        );
        isSnackBarDisplayed = true;
      }
    });
  }

  void updateState(String category) async {
    final professionalServiceEntries = await professionalServiceController
        .getProfessionalServices(category)
        .first;

    setState(() {
      filteredEntries = professionalServiceEntries;
    });
  }

  final profileController = ProfileController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = ThemeData(
      // useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            Colors.deepPurple, // Example color, ensure it's not conflicting
      ),
    );

    return Theme(
        data: themeData,
        child: Scaffold(
          // App bar with a title and a logout button.
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Center(
                child: Text("My Services",
                    style: GoogleFonts.lilitaOne(
                      color: Colors.white,
                      fontSize: 48.0,
                    ))),
            backgroundColor: Colors.deepPurple,
          ),

          // Body of the widget using a StreamBuilder to listen for changes
          // in the professionalServiceCollection  and reflect them in the UI in real-time.
          body: StreamBuilder<List<ProfessionalService>>(
            stream: professionalServiceController.getAllProfessionalServices(),
            builder: (context, snapshot) {
              // Show a loading indicator until data is fetched from Firestore.
              if (!snapshot.hasData) return CircularProgressIndicator();

              List<ProfessionalService> professionalServices =
                  (!filteredEntries.isEmpty) ? filteredEntries : snapshot.data!;
              // professionalServices

              String? lastCategory;

              return ListView.builder(
                itemCount: professionalServices.length,
                itemBuilder: (context, index) {
                  final entry = professionalServices[index];
                  if (lastCategory == null || entry.category != lastCategory) {
                    final headerText = entry.category;
                    lastCategory = entry.category!;

                    return Column(
                      children: [
                        DateHeader(text: headerText),
                        Card(
                          margin: EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onLongPress: () {
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // BuildImageFromUrl(entry),
                                  //TODO: DO WEE= NEED AN IMAGe HERE?
                                  Row(
                                    children: [
                                      // BuildImageFromUrl(entry),
                                      Text(
                                        'Technician: ${entry.technicianAlias}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Spacer(),
                                      BuildImageFromUrl(entry),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '${entry.serviceDescription}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 15),
                                  Row(
                                    children: [
                                      // RatingEvaluator(entry),
                                      // RatingEvaluator2(entry),
                                      Spacer(),
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () async {
                                          print(
                                              'entry with id: ${entry!.id} was selected to delete');
                                          //TODO: IMPLEMENT OR NOT
                                          String? userType =
                                              await profileController
                                                  .getUserType(FirebaseAuth
                                                      .instance
                                                      .currentUser!
                                                      .uid);
                                          if (userType! ==
                                              "Service Associate") {
                                            await professionalServiceController
                                                .deleteProfessionalService(
                                                    entry!.id);

                                            final serviceEntries =
                                                await professionalServiceController
                                                    .getAllProfessionalServices()
                                                    .first;

                                            setState(() {
                                              // Initialize filteredEntries with a copy of serviceEntries
                                              filteredEntries = List<
                                                      ProfessionalService>.from(
                                                  serviceEntries);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.serviceDescription,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                '${entry.serviceDescription}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 15),
                              Row(
                                children: [
                                  RatingEvaluator(entry),
                                  Spacer(),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () async {
                                      await professionalServiceController
                                          .deleteProfessionalService(entry!.id);

                                      final serviceEntries =
                                          await professionalServiceController
                                              .getAllProfessionalServices()
                                              .first;

                                      setState(() {
                                        // Initialize filteredEntries with a copy of serviceEntries
                                        filteredEntries =
                                            List<ProfessionalService>.from(
                                                serviceEntries);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),

          // Floating action button to open a dialog for adding a new service entry of a specific service category
          floatingActionButton: FloatingActionButton(
            tooltip: "Add my service",
            onPressed: () async {
              String? userType = await profileController
                  .getUserType(FirebaseAuth.instance.currentUser!.uid);
              if (userType! == "Service Associate") {
                showDialog(
                  context: context,
                  builder: (context) =>
                      ServiceEntryView.withInheritedTheme(categoryName),
                );
              } else {
                print("userType wasnt provider!");
              }
            },
            child: Icon(Icons.add),
          ),
        ));
  }
}

Row RatingEvaluator(ProfessionalService entry) {
  Map<String, int> reviewsMap = entry.reviewsMap ?? {};
  int averageRating = 5;
  final entryValueOrRatingList = reviewsMap!.values.toList();
  print('entryValueOrRatingList.length ${entryValueOrRatingList.length}');
  if (entryValueOrRatingList.isNotEmpty) {
    // Calculate the average
    int sum = 0;
    for (int rate in entryValueOrRatingList) {
      sum = sum + rate;
    }
    averageRating = (sum / entryValueOrRatingList.length).toInt();
    // Now 'averageRating' contains the average of ratings in the list
    print('Average Rating: $averageRating');
  } else {
    // Handle the case where the list is empty (to avoid division by zero)
    print('No ratings available.');
  }

  switch (averageRating) {
    case (1):
      return Row(children: [
        Icon(Icons.star),
      ]);
    case (2):
      return Row(children: [Icon(Icons.star), Icon(Icons.star)]);
    case (3):
      return Row(
          children: [Icon(Icons.star), Icon(Icons.star), Icon(Icons.star)]);
    case (4):
      return Row(children: [
        Icon(Icons.star),
        Icon(Icons.star),
        Icon(Icons.star),
        Icon(Icons.star)
      ]);
    case (5):
      return Row(children: [
        Icon(Icons.star),
        Icon(Icons.star),
        Icon(Icons.star),
        Icon(Icons.star),
        Icon(Icons.star)
      ]);
    default:
      return Row(); // Handle other cases or return an empty row if the rating is not 1-5.
  }
}

Row RatingEvaluator2(ProfessionalService entry) {
  Map<String, int> reviewsMap = entry.reviewsMap ?? {};
  int averageRating = 5;
  final entryValueOrRatingList = reviewsMap!.values.toList();
  print('entryValueOrRatingList.length ${entryValueOrRatingList.length}');
  if (entryValueOrRatingList.isNotEmpty) {
    // Calculate the average
    int sum = 0;
    for (int rate in entryValueOrRatingList) {
      sum = sum + rate;
    }
    averageRating = (sum / entryValueOrRatingList.length).toInt();
    // Now 'averageRating' contains the average of ratings in the list
    print('Average Rating: $averageRating');
  } else {
    // Handle the case where the list is empty (to avoid division by zero)
    print('No ratings available.');
  }

  switch (averageRating) {
    case (1):
      return Row(children: [
        Icon(
          Icons.sentiment_very_dissatisfied,
          color: Colors.red,
        )
      ]);
    case (2):
      return Row(children: [
        Icon(
          Icons.sentiment_dissatisfied,
          color: Colors.yellow.shade700,
        ),
        Icon(
          Icons.sentiment_dissatisfied,
          color: Colors.yellow.shade700,
        )
      ]);
    case (3):
      return Row(children: [
        Icon(
          Icons.sentiment_neutral,
          color: Colors.amber,
        ),
        Icon(
          Icons.sentiment_neutral,
          color: Colors.amber,
        ),
        Icon(
          Icons.sentiment_neutral,
          color: Colors.amber,
        )
      ]);
    case (4):
      return Row(children: [
        Icon(
          Icons.sentiment_satisfied,
          color: Colors.lightGreen,
        ),
        Icon(
          Icons.sentiment_satisfied,
          color: Colors.lightGreen,
        ),
        Icon(
          Icons.sentiment_satisfied,
          color: Colors.lightGreen,
        ),
        Icon(
          Icons.sentiment_satisfied,
          color: Colors.lightGreen,
        )
      ]);
    case (5):
      return Row(children: [
        Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.green,
        ),
        Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.green,
        ),
        Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.green,
        ),
        Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.green,
        ),
        Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.green,
        ),
      ]);
    default:
      return Row(); // Handle other cases or return an empty row if the rating is not 1-5.
  }
}

class Month {
  int num;
  String name;

  Month(this.num, this.name);

  String get Name {
    return name;
  }

  int get Number {
    return num;
  }
}

class DateHeader extends StatelessWidget {
  final String text;

  const DateHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(8.0),
        child: Text(text,
            style: GoogleFonts.lilitaOne(
              color: Colors.deepPurple,
              fontSize: 30.0,
            )));
  }
}
