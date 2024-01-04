import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_squad/controller/professional_service_controller.dart';
import 'package:service_squad/view/review_entry_view.dart';
import 'package:service_squad/view/service_entry_view.dart';
import 'package:service_squad/view_2.0/main_view.dart';
import '../controller/profile_controller.dart';
import '../model/professional_service.dart';

/// A stateless widget representing the main page where users can view
/// the reviews of each professional service reviews after authentication.
class ReviewsView extends StatefulWidget {
// Constructor to create a HomePage widget.
  ReviewsView({Key? key}) : super(key: key);
  bool isDark = false;
  List<String?>? reviewsList;
  Map<String, int>? reviewsMap;

  late ProfessionalService professionalService;

  ReviewsView.forEachProfessionalService(
      bool inheritedIsDark, ProfessionalService professionalService) {
    isDark = inheritedIsDark;
    reviewsList = professionalService.reviewList ?? [];
    reviewsMap = professionalService.reviewsMap ?? {};

    this.professionalService = professionalService;
  }

  @override
  State<ReviewsView> createState() =>
      _ReviewsViewState.withPersistedThemeAndCategory(
          isDark, professionalService, reviewsList, reviewsMap);
}

class _ReviewsViewState extends State<ReviewsView> {
// Instance of CarService to interact with Firestore for CRUD operations on cars.
  final ProfessionalServiceController professionalServiceController =
      ProfessionalServiceController();
  String? selectedCategory;
  bool isDark;
  List<ProfessionalService> filteredEntries = [];
  final TextEditingController searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late List<String?>? reviewsList;
  late Map<String, int>? reviewsMap;
  XFile? _image;
  late ProfessionalService service;

  _ReviewsViewState.withPersistedThemeAndCategory(
      this.isDark, this.service, this.reviewsList, this.reviewsMap);

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
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
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light);

    return Theme(
        data: themeData,
        child: Scaffold(
          // App bar with a title and a logout button.
          appBar: AppBar(
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: IconButton(
              color: Colors.white,
              icon: Icon(Icons.arrow_back_outlined),
              // Sign out the user on pressing the logout button.
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      // builder: (context) => CategoriesView.WithPersistedThemeAndCategory(
                      //     false, service.category),),
                      builder: (context) => MainScreen()),
                );
              },
            ),
            backgroundColor: Colors.deepPurple,
            title: Center(
                child: Text("Reviews",
                    style: GoogleFonts.lilitaOne(
                      color: Colors.white,
                      fontSize: 48.0,
                    ))),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(48.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
              ),
            ),
          ),
          body: ListView.builder(
            itemCount: reviewsMap!.keys.length,
            itemBuilder: (context, index) {
              final entryKeyOrReview = reviewsMap!.keys.toList()[index];
              final entryValueOrRating = reviewsMap![entryKeyOrReview];
              return Column(
                children: [
                  Card(
                    margin: EdgeInsets.all(8.0),
                    child: GestureDetector(
                      // onLongPress: () {
                      //   // Perform your action here when the Card is long-pressed.
                      //   return;
                      // },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Column(children: [
                            Text(
                              '${entryKeyOrReview}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Spacer(),
                            Row(children: [
                              SizedBox(
                                height: 10,
                              ),
                              Spacer(),
                              RatingEvaluator2(entryValueOrRating!)
                            ])
                            // SizedBox(height: 10,),
                            //   RatingEvaluator2(entryValueOrRating!),
                            // ])
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
              // }
            },
          ),
          // Floating action button to open a dialog for adding a new service entry of a specific service category
          floatingActionButton: FloatingActionButton(
            tooltip: "Add a review",
            onPressed: () async {
              String? userType = await profileController
                  .getUserType(FirebaseAuth.instance.currentUser!.uid);
              // if (userType! != "Service Associate") {
              //   () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        ReviewEntryView.withInheritedTheme(isDark, service)),
              );
              print('reached on press!');
              // Navigator.of(context).pop();
              // };
              // } else {
              //   print("userType was service associate!");
              // }
            },
            child: Icon(Icons.add),
          ),
        ));
  }
}

Future<Widget> displayOrHideFloatingActionButtonBasedOnUserRole(
    {required bool isDark,
    required String categoryName,
    required BuildContext context}) async {
  ProfileController profileController = ProfileController();

  String? userType = await profileController
      .getUserType(FirebaseAuth.instance.currentUser!.uid);

  if (userType! == "Service Associate") {
    return FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: "Add new service",
        onPressed: () async {
          showDialog(
            context: context,
            builder: (context) =>
                ServiceEntryView.withInheritedTheme(categoryName),
          );
        });
  } else {
    return SizedBox(height: 0.0);
  }
}

Widget BuildImageFromUrl(ProfessionalService entry) {
  if (entry.imagePath != null) {
    return Center(
        child: ClipOval(
      child: Image.network(
        entry.imagePath!,
        height: 65, // Set the desired height
        width: 65, // Take the available width
        fit: BoxFit.fill, // Adjust how the image is displayed
      ),
    ));
  } else {
    // If entry.imagePath is null, display a placeholder or an empty container
    return Container(); // You can customize this to show a placeholder image
  }
}

Row RatingEvaluatorVersion2(int entryRating) {
  switch (entryRating) {
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

Row RatingEvaluator2(int entryRating) {
  switch (entryRating) {
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
