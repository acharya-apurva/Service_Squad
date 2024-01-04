import 'package:flutter/material.dart';
import 'package:service_squad/view_2.0/profile_view_2.0.dart';
import 'package:service_squad/view_2.0/messages_view.dart';
import 'package:service_squad/view_2.0/services_list_view_2.0.dart';
import 'package:service_squad/view_2.0/services_list_view_professional.dart';
import 'package:service_squad/view/message_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_squad/controller/profile_controller.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

String? selectedUserType = 'Select an option';

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;
  final ProfileController profileController = ProfileController();
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid; // Assuming FirebaseAuth is used for user management
    if (currentUserId != null) {
      checkTechnicalAlias(currentUserId!);
      fetchUserType(currentUserId!);
    }



  }


  Future<void> fetchUserType(String uid) async {
    String? userType = await profileController.getUserType(uid);
    if (userType != null) {
      setState(() {
        selectedUserType = userType;
      });
    }
  }


  Future<void> checkTechnicalAlias(String uid) async {
    String? technicalAlias = await profileController.gettechnicianAlias(uid);
    String? userType = await profileController.getUserType(uid);
    if (technicalAlias == "" || userType=="Select an option") {
      setState(() {
        _currentIndex = 2;
      });
    } else {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  Widget getServicesView() {
    updateFcmToken();  // Call the method to update the token
    // Determine which view to return based on user type

    print('Selected User Typeeeeeeeeeee');
    print(selectedUserType);

    if (selectedUserType == 'Client') {
      return CategoriesView();
    } else if (selectedUserType == 'Service Associate') {
      return ProfessionalListServicesView();
    } else {
      return MessagesView();
    }
  }



  List<Widget> get _children => [
    getServicesView(),
    //MessagesView(),
    MessageScreen(),
    ProfileView(),
  ];

  Future<void> updateFcmToken() async {
  String? userEmail = FirebaseAuth.instance.currentUser?.email;
  if (userEmail != null) {
    String? token = await FirebaseMessaging.instance.getToken();
    print('START TO GET TOKENTOKENTOKENTOKENTOKEN  ${token}');

    QuerySnapshot userDocs = await FirebaseFirestore.instance.collection('users')
                                          .where('email', isEqualTo: userEmail)
                                          .get();
    
    if (userDocs.docs.isEmpty) {
      // Create the document if it doesn't exist
      await FirebaseFirestore.instance.collection('users').add({
        'email': userEmail,
        'fcmToken': token,
        // add other user details as necessary
      });
    } else {
      // Update the document
      if (token != null) {
        DocumentReference userDocRef = userDocs.docs.first.reference;
        await userDocRef.update({'fcmToken': token});
      }
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.list),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.mail),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
      if (selectedUserType != 'Select an option' || selectedUserType != ""|| selectedUserType != null ) {
        setState(() {
          _currentIndex = index;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a User Type in Profile and Click Save'),
            backgroundColor: Colors.red,
          ),
        );
      }
  }
}

