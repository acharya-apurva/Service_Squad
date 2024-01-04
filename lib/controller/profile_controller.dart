import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileController{
  Future<String?> getUserType(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userSnapshot.exists) {

        // Check if the 'userType' field exists in the document
        if (userSnapshot.data()!.containsKey('userType')) {
          // Return the user type
          print('userSnapshot.data()!["userType"]: ${userSnapshot.data()!['userType']}');
          return userSnapshot.data()!['userType'];
        }
      }
      print("userType is: ${userSnapshot.data()!['userType']}");

      // Return null if the user document or 'userType' field doesn't exist
      return null;
    } catch (e) {
      // Handle any errors that occur during the process
      print("Error getting user type: $e");
      return null;
    }
  }

  Future<String> getUserLocation(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userSnapshot.exists) {

        // Check if the 'userType' field exists in the document
        if (userSnapshot.data()!.containsKey('userLocation')) {
          // Return the user type
          print('userSnapshot.data()!["userLocation"]: ${userSnapshot.data()!['userLocation']}');
          return userSnapshot.data()!['userLocation'];
        }
      }
      print("userLocation is: ${userSnapshot.data()!['userLocation']}");

      // Return null if the user document or 'userType' field doesn't exist
      return "";
    } catch (e) {
      // Handle any errors that occur during the process
      print("Error getting user type: $e");
      return "";
    }
  }

  Future<String> gettechnicianAlias(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userSnapshot.exists) {

        // Check if the 'userType' field exists in the document
        if (userSnapshot.data()!.containsKey('technicianAlias')) {
          // Return the user type
          print('userSnapshot.data()!["technicianAlias"]: ${userSnapshot.data()!['technicianAlias']}');
          return userSnapshot.data()!['technicianAlias'];
        }
      }
      print("technicianAlias is: ${userSnapshot.data()!['technicianAlias']}");

      // Return null if the user document or 'userType' field doesn't exist
      return "";
    } catch (e) {
      // Handle any errors that occur during the process
      print("Error getting user type: $e");
      return "";
    }
  }

  void setTechnicianAlias(String uid, String technicianAlias) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'technicianAlias': technicianAlias}, SetOptions(merge: true));
  }

  void setUserType(String uid, String userType) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'userType': userType}, SetOptions(merge: true));
  }

  void setEmail(String uid, String email) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'userEmail': email}, SetOptions(merge: true));
  }

  void setUserLocation(String uid, String location) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'userLocation': location}, SetOptions(merge: true));
  }

  void setMobileNumber(String uid, String mobileNumber) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'mobileNumber': mobileNumber}, SetOptions(merge: true));
  }

  void setAboutMe(String uid, String aboutMe) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'userAbout': aboutMe}, SetOptions(merge: true));
  }
}