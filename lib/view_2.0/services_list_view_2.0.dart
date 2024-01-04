import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_squad/controller/professional_service_controller.dart';
import 'package:service_squad/view/reviews_list_view.dart';
import '../controller/profile_controller.dart';
import '../model/professional_service.dart';
import '../view/book_service_view.dart';

class CategoriesView extends StatefulWidget {
  CategoriesView({Key? key}) : super(key: key);
  bool isDark = false;
  String categoryToPopulate = '';

  CategoriesView.WithPersistedThemeAndCategory(
      bool inheritedIsDark, String categoryName) {
    isDark = inheritedIsDark;
    categoryToPopulate = categoryName;
  }

  @override
  State<CategoriesView> createState() =>
      _CategoriesViewState.withPersistedThemeAndCategory(
          isDark, categoryToPopulate);
}

class _CategoriesViewState extends State<CategoriesView> {
// Instance of CarService to interact with Firestore for CRUD operations on cars.
  final ProfessionalServiceController professionalServiceController =
      ProfessionalServiceController();
  String? selectedCategory;
  bool isDark;
  List<ProfessionalService> filteredEntries = [];
  final TextEditingController searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String categoryName;
  XFile? _image;

  _CategoriesViewState.withPersistedThemeAndCategory(
      this.isDark, this.categoryName);

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  // to sort the ratings and the price of the entries
  void sortEntries(String sortBy) async{
    final serviceEntries = selectedCategory != null
        ? await professionalServiceController
        .getProfessionalServices(selectedCategory!.toLowerCase())
        .first
        : await professionalServiceController
        .getAllAvailableProfessionalServiceCollections()
        .first;

    filteredEntries = List<ProfessionalService>.from(serviceEntries);

    setState(() {
      if (sortBy == 'rating') {
        filteredEntries.sort((a, b) => b.rating!.compareTo(a.rating as num));
      } else if (sortBy == 'price') {
        // Sort by price in ascending order
        filteredEntries.sort((a, b) => a.wage!.compareTo(b.wage as num));
      }
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
                        email: FirebaseAuth.instance.currentUser?.email,
                        technicianAlias:
                            professionalServiceEntry.technicianAlias));

                updateState(professionalServiceEntry.category);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Center(child: Text('Entry successfully saved!')),
                      backgroundColor: Colors.green),
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
            .getProfessionalServices(selectedCategory!.toLowerCase())
            .first
        : await professionalServiceController
            .getAllAvailableProfessionalServiceCollections()
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

    final serviceEntries = (selectedCategory != null && selectedCategory != '')
        ? await professionalServiceController
            .getAllAvailableProfessionalServiceCollectionsByCategory(
                selectedCategory!)
            .first
        : await professionalServiceController
            .getAllAvailableProfessionalServiceCollections()
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
      if (searchController.text != '' && queryIsLocation) {
        filteredEntries = filteredEntries.where((entry) {
          print(
              'entry.location.toLowerCase() is ${entry.location.toLowerCase()}');
          return entry.location.toLowerCase().contains(queryText.toLowerCase());
        }).toList();
      }
      if (selectedCategory != null &&
          selectedCategory != '' &&
          searchController.text != '' &&
          queryIsLocation &&
          isOnSubmitted) {
        print(
            'in filtering stage selectedCategory is: ${selectedCategory!.toLowerCase()}');
        filteredEntries = filteredEntries.where((entry) {
          return ((entry.category.toLowerCase() ==
                  selectedCategory!.toLowerCase()) ||
              (entry.location.toLowerCase().contains(queryText.toLowerCase())));
        }).toList();
      }

      // Show a message if no matches are found
      print('filteredEntries.length: ${filteredEntries.length}');
      print('serviceEntries.length: ${serviceEntries.length}');
      print('selectedCategory is: ${selectedCategory}');

      if (isOnSubmitted &&
              searchController.text != '' &&
              !isSnackBarDisplayed &&
              filteredEntries.length == 0
          ) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Center(child: Text('No match found!')),
            duration: Duration(milliseconds: 500),
          ),
        );
        selectedCategory = '';
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
              child: Text(
                  "Services",
                  style: GoogleFonts.lilitaOne(
                    color: Colors.white,
                    fontSize: 48.0,
                  )
              ),
            ),
            backgroundColor: Colors.deepPurple,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 250), // Shortened maxWidth
                        child: SearchBar(
                          hintText: "location...",
                          controller: searchController,
                          padding: const MaterialStatePropertyAll<EdgeInsets>(
                            EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          onChanged: (_) async {
                            applySearchBarLocationBasedQueryAndUpdateState(false);
                          },
                          onSubmitted: (_) async {
                            applySearchBarLocationBasedQueryAndUpdateState(true);
                          },
                          leading: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () async {
                              applySearchBarLocationBasedQueryAndUpdateState(false);
                            },
                          ),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String category) async {
                        setState(() {
                          selectedCategory = category;
                        });
                        applySearchBarLocationBasedQueryAndUpdateState(false);
                      },
                      icon: Icon(
                        Icons.filter_list_alt,
                        color: Colors.white,
                      ),
                      itemBuilder: (BuildContext context) {
                        final List<String> serviceCategories = [
                          'House Keeping',
                          'Snow Clearance',
                          'Handy Services',
                          'Lawn Mowing',
                          'All'
                        ];
                        return serviceCategories.map((String category) {
                          return PopupMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList();
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        sortEntries(value);
                      },
                      icon: Icon(
                        Icons.sort,
                        color: Colors.white,
                      ),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'rating',
                          child: Text('Sort by Rating Desc'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'price',
                          child: Text('Sort by Price Asc'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body of the widget using a StreamBuilder to listen for changes
          // in the professionalServiceCollection  and reflect them in the UI in real-time.
          body: StreamBuilder<List<ProfessionalService>>(
            stream: professionalServiceController
                .getAllAvailableProfessionalServiceCollections(),
            builder: (context, snapshot) {
              // Show a loading indicator until data is fetched from Firestore.
              if (!snapshot.hasData) return CircularProgressIndicator();

              List<ProfessionalService> professionalServices =
                  (!filteredEntries.isEmpty) ? filteredEntries : snapshot.data!;

              String? lastCategory;

              return ListView.builder(
                itemCount: professionalServices.length,
                itemBuilder: (context, index) {
                  final entry = professionalServices[index];
                  return Column(
                      children: [
                        Card(
                          margin: EdgeInsets.all(8.0),
                          child: GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BuildImageFromUrl(entry),
                                  Center(
                                      child: Text('${entry.category}',
                                          style: GoogleFonts.lilitaOne(
                                            color: Colors.deepPurple,
                                            fontSize: 30.0,
                                          ))),
                                  Row(
                                    children: [
                                      // BuildImageFromUrl(entry),
                                      // Icon(Icons.face),
                                      // Spacer(),
                                      Text(
                                        'Technician: ${entry.technicianAlias}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.rate_review_rounded),
                                        onPressed: () async {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ReviewsView
                                                  .forEachProfessionalService(
                                                      isDark, entry),
                                            ),
                                          );
                                          print(
                                              '${FirebaseAuth.instance.currentUser!.email}');
                                          print(
                                              'selectedProfessionalServiceCategory is ${entry.category}');
                                        },
                                      )
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Location: ${entry.location}',
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    '${entry.serviceDescription}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Service Hourly Rate: ${entry.wage}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Row(
                                    children: [
                                      // RatingEvaluator(entry),
                                      RatingEvaluator2(entry),
                                      Spacer(),
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.calendar_today),
                                        onPressed: () async {
                                          print(
                                              '${FirebaseAuth.instance.currentUser!.email}');
                                          print(
                                              'selectedCategory is ${selectedCategory}');
                                          print(
                                              '${FirebaseAuth.instance.currentUser!.email}');
                                          print(
                                              'selectedCategory is ${selectedCategory}');

                                          String? userType =
                                              await profileController
                                                  .getUserType(FirebaseAuth
                                                      .instance
                                                      .currentUser!
                                                      .uid);
                                          if (userType != null &&
                                              userType == "Client") {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BookServiceView(
                                                  service: entry,
                                                ),
                                              ),
                                            );
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
                },
              );
            },
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