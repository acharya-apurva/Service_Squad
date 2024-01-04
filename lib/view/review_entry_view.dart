import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_squad/view/reviews_list_view.dart';
import '../controller/professional_service_controller.dart';
import '../model/professional_service.dart';

class ReviewEntryView extends StatefulWidget {
  bool isDark;
  ProfessionalService professionalService;

  ReviewEntryView.withInheritedTheme(this.isDark, this.professionalService);

  @override
  // _NewEntryViewState createState() => _NewEntryViewState();
  _NewEntryViewState createState() =>
      _NewEntryViewState.withInheritedThemeAndCategory(
          isDark, professionalService);
}

class _NewEntryViewState extends State<ReviewEntryView> {
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();

  String? review;
  int? rating;
  final service;

  _NewEntryViewState.withInheritedThemeAndCategory(
      bool isDark, ProfessionalService professionalService)
      : service = professionalService;

  void _saveReviewEntry() async {
    ProfessionalService professionalService = service;
    final professionalServiceController = ProfessionalServiceController();
    review = reviewController.text;
    // rating = int.tryParse(ratingController.text)?? 5;

    if (review == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Center(
                child: Text('Review can not be left empty!',
                    style: TextStyle(
                      color: Colors.white, // Customize the hint text color
                      fontSize: 12, // Customize the hint text font size
                    ))),
            backgroundColor: Colors.red),
      );
      return;
    }
    List<String?> newReviewList = professionalService.reviewList ?? [];
    newReviewList.add(review);

    Map<String, int> newReviewsMap = professionalService.reviewsMap ?? {};
    newReviewsMap[review!] = rating!;

    ProfessionalService newProfessionalService = ProfessionalService(
        id: professionalService.id,
        category: professionalService.category,
        serviceDescription: professionalService.serviceDescription,
        wage: professionalService.wage,
        rating: rating,
        reviewsMap: newReviewsMap,
        location: professionalService.location,
        email: professionalService.email,
        technicianAlias: professionalService.technicianAlias!,
        imagePath: professionalService.imagePath,
        reviewList: newReviewList);

    professionalServiceController
        .updateProfessionalService(newProfessionalService);

    reviewController.clear();
    ratingController.clear();

    print('rating is: $rating');
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Center(
                child: Text('Review successfully saved!',
                    style: TextStyle(
                      color: Colors.white, // Customize the hint text color
                      fontSize: 12, // Customize the hint text font size
                    ))),
            backgroundColor: Colors.green),
      );
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ReviewsView.forEachProfessionalService(false, service)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Unexpected error ocured: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData =
        ThemeData(useMaterial3: true, brightness: Brightness.light);

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: Center(
              child: Text("Add a Review",
                  style: GoogleFonts.lilitaOne(
                    color: Colors.white,
                    fontSize: 48.0,
                  ))),
          // leadingWidth: 0.0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_outlined),
            tooltip: 'Go back',
            color: Colors.white,
            onPressed: () {
              print('pressed arrow_back_outlined in add a review');
              // Navigator.of(context).pop();

              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ReviewsView.forEachProfessionalService(false, service)),
              );
            },
          ),
        ),

        // body: Column(
        //   children: [
        //     Expanded(
        //       child:
        //         padding: EdgeInsets.all(12.0),
        //         child: _currentWidget,
        //       ),
        //     ),
        //     if (_bottomNavBar != null) _bottomNavBar!,
        //   ],
        // ),
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 150.0),

                    TextField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        labelText: 'write a review',
                        hintText:
                            'write a review', //TODO: BETTER MAKE IT A DROP DOWN OR RADIO BUTTON
                      ),
                      maxLength: 100, // Set the maximum character limit
                      maxLines: null, // Allow multiple lines of text
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Rate your experience:'),
                        Spacer(),
                        RatingBar.builder(
                          initialRating: 3,
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            switch (index) {
                              case 0:
                                return Icon(
                                  Icons.sentiment_very_dissatisfied,
                                  color: Colors.red,
                                );
                              case 1:
                                return Icon(
                                  Icons.sentiment_dissatisfied,
                                  color: Colors.redAccent,
                                );
                              case 2:
                                return Icon(
                                  Icons.sentiment_neutral,
                                  color: Colors.amber,
                                );
                              case 3:
                                return Icon(
                                  Icons.sentiment_satisfied,
                                  color: Colors.lightGreen,
                                );
                              case 4:
                                return Icon(
                                  Icons.sentiment_very_satisfied,
                                  color: Colors.green,
                                );
                              default:
                                return Container(height: 0.0);
                            }
                          },
                          onRatingUpdate: (ratingValue) {
                            print(ratingValue);
                            rating = ratingValue.toInt();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 50),
                    // Container(height: 50.0,),
                    ElevatedButton(
                      onPressed: _saveReviewEntry,
                      child: Text('Save Entry'),
                    ),
                  ],
                ))));
  }
}

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Error Exception'),
      content: const Text(
          'You are already providing this service, instead of creating new posting modify your existing ad!'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'OK'),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
