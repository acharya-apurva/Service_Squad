import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controller/professional_service_controller.dart';
import '../controller/profile_controller.dart';
import '../model/professional_service.dart';
import 'package:service_squad/view_2.0/main_view.dart';

class ServiceEntryView extends StatefulWidget {
  String category;

  ServiceEntryView.withInheritedTheme(this.category);

  @override
  // _NewEntryViewState createState() => _NewEntryViewState();
  _NewEntryViewState createState() =>
      _NewEntryViewState.withInheritedThemeAndCategory(category);
}

class _NewEntryViewState extends State<ServiceEntryView> {
  late final TextEditingController descriptionController;
  late final TextEditingController categoryController;

  late final TextEditingController technicianAliasController;

  late final TextEditingController wageController;

  double? wage;
  String? technicianAlias;
  double rating = 5.0; // Initial rating value
  late String serviceDescription;
  late String category;
  String? imagePath;
  List<String?> imagePathList = [];
  var professionalServiceController = ProfessionalServiceController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  late bool isDark;

  _NewEntryViewState.withInheritedThemeAndCategory(String category) {
    this.isDark = false;
    this.category = category;
    descriptionController = TextEditingController();
    categoryController = TextEditingController(text: '${category}');
    technicianAliasController = TextEditingController();
    wageController = TextEditingController();
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = image;
    });
  }

  Future<String?> _uploadImageToFirebaseAndReturnDownlaodUrl() async {
    if (_image == null) return null;
    String? downloadURL = null;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    final firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child('images/${currentUser.uid}/${_image!.name}');

    try {
      final uploadTask = await firebaseStorageRef.putFile(File(_image!.path));
      if (uploadTask.state == TaskState.success) {
        downloadURL = await firebaseStorageRef.getDownloadURL();

        print("Uploaded to: $downloadURL");
      }
    } catch (e) {
      print("Failed to upload image: $e");
    }
    return downloadURL;
  }

  void _saveServiceEntry() async {
    serviceDescription = descriptionController.text;
    category = categoryController.text;
    wage = double.parse(
        wageController.text.isNotEmpty ? wageController.text : '1.0');
    // technicianAlias = technicianAliasController.text ?? 'Unspecified';
    technicianAlias = technicianAliasController.text != ''
        ? technicianAliasController.text
        : await ProfileController()
            .gettechnicianAlias(FirebaseAuth.instance.currentUser!.uid);

    String location = await ProfileController()
        .getUserLocation(FirebaseAuth.instance.currentUser!.uid);

    imagePath = await _uploadImageToFirebaseAndReturnDownlaodUrl();
    print('imagePath is : $imagePath');
    imagePathList.add(imagePath);

    if (serviceDescription == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Center(
                child: Text('Description can not be left empty!',
                    style: TextStyle(
                      color: Colors.white, // Customize the hint text color
                      fontSize: 12, // Customize the hint text font size
                    ))),
            backgroundColor: Colors.red),
      );
      return;
    }

    ProfessionalService professionalService = ProfessionalService(
        // category: categoryController.text,
        category: category,
        serviceDescription: serviceDescription,
        wage: wage,
        rating: 5,
        location: location,
        technicianAlias: technicianAlias!,
        imagePath: imagePath,
        email: FirebaseAuth.instance.currentUser!.email!);

    print('new professionalService location is: ${location}');

    bool successfullyAdded = await professionalServiceController
        .addProfessionalService(professionalService);

    descriptionController.clear();
    print('rating is: $rating');
    try {
      if (successfullyAdded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Center(
                  child: Text('Entry successfully saved!',
                      style: TextStyle(
                        color: Colors.white, // Customize the hint text color
                        fontSize: 12, // Customize the hint text font size
                      ))),
              backgroundColor: Colors.deepPurple),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MainScreen() //With Persisted Theme and Category Removed for now
                ));
      } else if (!successfullyAdded) {
        // Show the error dialog when the button is pressed
        showDialog(
          context: context,
          builder: (context) {
            return ErrorDialog();
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Unexpected error ocured: $e'),
            backgroundColor: Colors.deepPurple),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light);

    return Theme(
        data: themeData,
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.deepPurple,
              title: Text("Add a Service",
                  style: GoogleFonts.lilitaOne(
                    color: isDark ? Colors.black87 : Colors.white,
                    fontSize: 48.0,
                  )),
              leading: IconButton(
                  icon: Icon(Icons.arrow_back_outlined),
                  tooltip: 'Go back',
                  color: isDark ? Colors.black87 : Colors.white,
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            ),
            body: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: categoryController,
                        decoration: InputDecoration(
                          labelText: 'Enter your service category',
                          hintText:
                              'Enter your service category', //TODO: BETTER MAKE IT A DROP DOWN OR RADIO BUTTON
                        ),
                        maxLength: 50, // Set the maximum character limit
                        maxLines: null, // Allow multiple lines of text
                      ),
                      TextField(
                        controller: technicianAliasController,
                        decoration: InputDecoration(
                            labelText: 'Enter your alias',
                            hintText:
                                'Enter the name you\'d like to be displayed' //TODO: BETTER MAKE IT A DROP DOWN OR RADIO BUTTON
                            ),
                        maxLength: 50, // Set the maximum character limit
                        maxLines: null, // Allow multiple lines of text
                      ),
                      SizedBox(height: 5),
                      TextField(
                        controller: wageController,
                        decoration: InputDecoration(
                          labelText: 'Enter your hourly rate',
                          hintText: 'Hourly wage',
                        ),
                        // maxLength: 140, // Set the maximum character limit
                        maxLines: null, // Allow multiple lines of text
                      ),
                      SizedBox(height: 5),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Service Description',
                          hintText:
                              'Enter the service description', //TODO: BETTER MAKE IT A DROP DOWN OR RADIO BUTTON
                        ),
                        maxLength: 100, // Set the maximum character limit
                        maxLines: null, // Allow multiple lines of text
                      ),
                      SizedBox(height: 5),
                      SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: _pickImageFromGallery,
                        child: Text('Add Image from Gallery'),
                      ),
                      ElevatedButton(
                        onPressed: _pickImageFromCamera,
                        child: Text('Add Image from Camera'),
                      ),
                      SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: _saveServiceEntry,
                        child: Text('Save Entry'),
                      ),
                    ],
                  ),
                ],
              ),
            )));
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
