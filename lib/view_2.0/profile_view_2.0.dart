import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_squad/controller/profile_controller.dart';
import 'package:service_squad/view_2.0/main_view.dart';
import '../view/auth_gate.dart';
import 'all_bookings_client_view.dart';
import 'all_bookings_provider_view.dart';

final GlobalKey<DropdownMenuExampleState> dropdownMenuKey = GlobalKey();

Future<String?> getUserLocation(String uid) async {
  try {
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userSnapshot.exists) {
      // Check if the 'userType' field exists in the document
      if (userSnapshot.data()!.containsKey('userLocation')) {
        // Return the user type
        return userSnapshot.data()!['userLocation'];
      }
    }

    // Return null if the user document or 'userType' field doesn't exist
    return null;
  } catch (e) {
    // Handle any errors that occur during the process
    print("Error getting user type: $e");
    return null;
  }
}

Future<String?> getUserType(String uid) async {
  try {
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userSnapshot.exists) {
      // Check if the 'userType' field exists in the document
      if (userSnapshot.data()!.containsKey('userType')) {
        // Return the user type
        return userSnapshot.data()!['userType'];
      }
    }

    // Return null if the user document or 'userType' field doesn't exist
    return null;
  } catch (e) {
    // Handle any errors that occur during the process
    print("Error getting user type: $e");
    return null;
  }
}

//TODO if the registration is completed then redirect to the category grid view
//TODO if the user is an associate when each grid is pressed pop up a new screen allowing to create a new posting of that category type

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}
DropdownMenuExample dropdownMenu = DropdownMenuExample(initialValue: 'Select an option');
class _ProfileViewState extends State<ProfileView> {
  TextEditingController userTypeControleer = TextEditingController();
  TextEditingController userLocationController = TextEditingController();
  TextEditingController userAliasController = TextEditingController();
  TextEditingController userAboutController = TextEditingController();
  TextEditingController useremailAddressController = TextEditingController();
  TextEditingController mobilePhoneNumberController = TextEditingController();
  DropdownMenuExample dropdownMenu = DropdownMenuExample(key: dropdownMenuKey, initialValue: 'Select an option');

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    // Fetch user data from Firestore
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        Map<String, dynamic> userData = userSnapshot.data()!;
        // Updating the controllers
        userLocationController.text = userData['userLocation'] ?? '';
        userAliasController.text = userData['technicianAlias'] ?? '';
        useremailAddressController.text = userData['userEmail'] ?? '';
        mobilePhoneNumberController.text = userData['mobileNumber'] ?? '';
        userAboutController.text = userData['userAbout'] ?? '';

        String userType = userData['userType'] ?? 'Select an option';
        if (dropdownMenuKey.currentState != null) {
          dropdownMenuKey.currentState!.updateValue(userType);
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      // Handle error state
    }
  }

  //TODO: BESIDES UTTING RED ATERICS ALERT THE USER NOT TO LEAVE LOCATION AND USER TYPE EMPTY
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.deepPurple,
          title: Center(
              child: Text("My Profile",
                  style: GoogleFonts.lilitaOne(
                    color: Colors.white,
                    fontSize: 48.0,
                  )))),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: dropdownMenu,
                  ),
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20.0,
                    ),
                  ),
                ],
              ),
              SizedBox(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: userLocationController,
                      decoration:
                      InputDecoration(labelText: "Set your location"),
                    ),
                  ),
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20.0,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: userAliasController,
                decoration: InputDecoration(labelText: "Set your alias"),
              ),
              TextField(
                controller: userAboutController,
                decoration: InputDecoration(labelText: "About Me"),
              ),
              TextField(
                controller: useremailAddressController,
                decoration: InputDecoration(labelText: "Edit your email"),
              ),
              TextField(
                controller: mobilePhoneNumberController,
                decoration: InputDecoration(labelText: "Edit your number"),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                child: Text('Save'),
                onPressed: () async {
                  ProfileController().setEmail(FirebaseAuth.instance.currentUser!.uid,
                      useremailAddressController.text);
                  ProfileController().setMobileNumber(FirebaseAuth.instance.currentUser!.uid,
                      mobilePhoneNumberController.text);
                  ProfileController().setUserLocation(FirebaseAuth.instance.currentUser!.uid,
                      userLocationController.text);
                  ProfileController().setAboutMe(FirebaseAuth.instance.currentUser!.uid, userAboutController.text);
                  ProfileController().setTechnicianAlias(
                      FirebaseAuth.instance.currentUser!.uid,
                      userAliasController.text);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(child:Text('Profile info was successfully updated!')),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Sign Out'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthGate(),
                    ),
                  );
                },
              ),

              SizedBox(height: 20,),
              ElevatedButton(
                child: Text('View bookings'),
                onPressed: () async {
                  if (selectedUserType != "Service Associate" &&
                      selectedUserType != "Client") {
                      // TODO: HANDLE THIS..
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) {
                            if (selectedUserType == "Service Associate") {
                              return AllBookingsProviderView();
                            }
                            return AllBookingsClientView();
                          }),
                    );
                  }
                }
              ),
              // Add any additional widgets you need
            ],
          ),
        ),
      ),
    );
  }
}

const List<String> list = <String>['Client', 'Service Associate'];

class DropdownMenuExample extends StatefulWidget {


  DropdownMenuExample({Key? key, required this.initialValue}) : super(key: key);
  final String initialValue;

  @override
  DropdownMenuExampleState createState() => DropdownMenuExampleState();
}

class DropdownMenuExampleState extends State<DropdownMenuExample> {
  late String dropdownValue;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.initialValue;
  }
  void updateValue(String newValue) {
    if (mounted) {
      setState(() {
        dropdownValue = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
        value: dropdownValue,
        onChanged: (String? value) {
          setState(() {
            dropdownValue = value!;
            ProfileController().setUserType(FirebaseAuth.instance.currentUser!.uid, dropdownValue);
            selectedUserType = dropdownValue;
          });
        },
        items: [
          // Add an additional item for the initial text
          DropdownMenuItem<String>(
            value: 'Select an option',
            child: Text('Select an option'),
          ),
          ...list.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ]);
  }
}










