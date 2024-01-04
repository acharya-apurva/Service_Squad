import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/professional_service.dart';

/// A service class that provides methods to perform CRUD operations
/// on user's ProfessionalService stored in Firestore.
class ProfessionalServiceController {
  /// The currently authenticated user from Firebase.
  final user = FirebaseAuth.instance.currentUser;

  /// A reference to the Firestore collection where the ProfessionalService for
  /// the current user are stored.
  late final CollectionReference individualUserProfessionalServiceCollection;

  /// A reference to the Firestore collection where the perfessional services to
  /// display to all customers.
  late final CollectionReference
      allProfessionalServiceCollectionToDisplayToCustomers;

  /// Constructor initializes the reference to the Firestore collection
  /// specific to the current user's ProfessionalService details.
  ProfessionalServiceController() {
    individualUserProfessionalServiceCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('professional_services');

    allProfessionalServiceCollectionToDisplayToCustomers = FirebaseFirestore
        .instance
        .collection('available_professional_services');
  }

  /// Adds a new service entry to Firestore and returns the document reference.
  Future<bool> addProfessionalService(
      ProfessionalService professionalServiceEntry) async {
    bool shouldAdd = true;
    final snapshot =
        await getAllProfessionalServices().first; // Wait for the first snapshot

    for (ProfessionalService professionalService in snapshot) {
      //add new only if the category already doesnt exist for the user
      if (professionalService.category == professionalServiceEntry.category) {
        shouldAdd = false;
        break;
      }
    }
    if (shouldAdd) {
      await individualUserProfessionalServiceCollection
          .add(professionalServiceEntry.toMap());
    }

    await allProfessionalServiceCollectionToDisplayToCustomers
        .add(professionalServiceEntry.toMap());
    return shouldAdd;
  }

  //For testing and admin use only to clear the docs in the collection
  Future<void>
      clearAllDocsInAllProfessionalServiceCollectionToDisplayToCustomers() async {
    try {
      // Get all documents in the collection
      QuerySnapshot querySnapshot =
          await individualUserProfessionalServiceCollection.get();

      // Iterate through the documents and delete each one
      for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
        await documentSnapshot.reference.delete();
      }

      print("All documents deleted successfully.");
    } catch (error) {
      print("Error clearing documents: $error");
    }
  }

  //For testing and admin use only to clear the docs in the collection
  Future<void>
      clearAllDocsInIndividualUserProfessionalServiceCollection() async {
    try {
      // Get all documents in the collection
      QuerySnapshot querySnapshot =
          await allProfessionalServiceCollectionToDisplayToCustomers.get();

      // Iterate through the documents and delete each one
      for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
        await documentSnapshot.reference.delete();
      }

      print("All documents deleted successfully.");
    } catch (error) {
      print("Error clearing documents: $error");
    }
  }

  Future<void> updateProfessionalService(
      ProfessionalService professionalService) async {
    try {
      QuerySnapshot querySnapshot2 =
      await allProfessionalServiceCollectionToDisplayToCustomers
          .where('id', isEqualTo: professionalService.id)
          .get();

      // Update the document in the global collection
      if (querySnapshot2.docs.isNotEmpty) {
        String documentId2 = querySnapshot2.docs.first.id;
        await allProfessionalServiceCollectionToDisplayToCustomers
            .doc(documentId2)
            .update(professionalService.toMap());
      } else {
        // Handle the case where the document is not found in the global collection
        print('Document not found in the global collection');
      }
    } catch (e) {
      // Handle other errors
      print('Error: $e');
    }
  }

  Future<ProfessionalService?> getProfessionalServiceByID(String id) async {
    QuerySnapshot querySnapshot =
      await allProfessionalServiceCollectionToDisplayToCustomers
          .where('id', isEqualTo: id)
          .get();
    if (querySnapshot.docs.isNotEmpty) {
      // Update the document in the individual user's collection
      String documentId = querySnapshot.docs.first.id;
      final doc = await allProfessionalServiceCollectionToDisplayToCustomers
          .doc(documentId).get();
      Map<String, dynamic>? map = doc.data() as Map<String, dynamic>?;

      if (map == null) {
        // Handle the case where the document doesn't contain data as expected
        return null;
      }
      return ProfessionalService.fromMap(map);
    }
    return null;
  }

  Future<void> deleteProfessionalService(String? id) async {
    try {
      // Query the collection to find the document ID based on the ID
      QuerySnapshot querySnapshot =
          await individualUserProfessionalServiceCollection
              .where('id', isEqualTo: id!)
              .get();

      QuerySnapshot querySnapshot2 =
          await allProfessionalServiceCollectionToDisplayToCustomers
              .where('id', isEqualTo: id!)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update the document in the individual user's collection
        String documentId = querySnapshot.docs.first.id;
        await individualUserProfessionalServiceCollection
            .doc(documentId)
            .delete();

        // Update the document in the global collection
        if (querySnapshot2.docs.isNotEmpty) {
          String documentId2 = querySnapshot2.docs.first.id;
          await allProfessionalServiceCollectionToDisplayToCustomers
              .doc(documentId2)
              .delete();
        } else {
          // Handle the case where the document is not found in the global collection
          print('Document not found in the global collection');
        }
      } else {
        print('Document not found');
      }
    } catch (e) {
      // Handle other errors
      print('Error: $e');
    }
  }

  /// Retrieves a stream of a list of `profesional services` objects associated
  /// with the current user from Firestore with specific category.
  Stream<List<ProfessionalService>> getProfessionalServices(
      String CategoryNameToRetrieve) {
    return individualUserProfessionalServiceCollection
        // return allProfessionalServiceCollectionToDisplayToCustomers
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ProfessionalService.fromMap(doc.data() as Map<String, dynamic>))
          .where((service) =>
              service.category.toLowerCase() ==
              CategoryNameToRetrieve.toLowerCase())
          .toList();
    });
  }

  Stream<List<ProfessionalService>> getAllProfessionalServices() {
    return individualUserProfessionalServiceCollection
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ProfessionalService.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<ProfessionalService>>
      getAllAvailableProfessionalServiceCollections() {
    CollectionReference allAvailableProfessionalServiceCollections =
        FirebaseFirestore.instance
            .collection('available_professional_services');
    return allAvailableProfessionalServiceCollections
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ProfessionalService.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<ProfessionalService>>
      getAllAvailableProfessionalServiceCollectionsByCategory(
          String categoryNameToRetrieve) {
    CollectionReference allAvailableProfessionalServiceCollections =
        FirebaseFirestore.instance
            .collection('available_professional_services');
    return allAvailableProfessionalServiceCollections
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ProfessionalService.fromMap(doc.data() as Map<String, dynamic>))
          .where((service) =>
              service.category.toLowerCase() ==
              categoryNameToRetrieve.toLowerCase())
          .toList();
    });
  }
}
