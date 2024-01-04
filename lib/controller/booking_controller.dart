
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_squad/controller/professional_service_controller.dart';
import 'package:service_squad/model/professional_service.dart';
import 'package:service_squad/model/service_booking_data.dart';

class BookingController {
  /// The currently authenticated user from Firebase.
  final user = FirebaseAuth.instance.currentUser;

  /// A reference to the Firestore collection where bookings are stored
  late final CollectionReference bookingsCollection;

  /// Constructor initializes the reference to the Firestore collection
  BookingController() {
    bookingsCollection = FirebaseFirestore.instance
        .collection('service_bookings');
  }

  /// Called to get all bookings matching a service id.
  Stream<List<ServiceBookingData?>> getBookingsForServiceID(String serviceID) {
    final query = bookingsCollection.where("serviceID", isEqualTo: serviceID);
    return query
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          ServiceBookingData.fromMap(doc)
      ).toList();
    });
  }

  /// Called to get all bookings for the authenticated service provider.
  Future<Stream<List<ServiceBookingData?>>> getBookingsForServiceProvider() async {
    final ps = ProfessionalServiceController();
    final stream = ps.getAllProfessionalServices();
    final services = await stream.first;
    List<String> ids = [];
    services.forEach((element) {
      if (element.id != null) {
        ids.add(element.id!);
      }
    });

    final matchingBookings = bookingsCollection.where("serviceID", whereIn: ids);
    return matchingBookings
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        final booking = ServiceBookingData.fromMap(doc);
        return booking;
      }).toList();
    });
  }

  Future<ProfessionalService?> getAssociatedProfessionalService(ServiceBookingData booking) async {
    final serviceController = ProfessionalServiceController();
    return await serviceController.getProfessionalServiceByID(booking.serviceID);
  }

  /// Returns all bookings for the authenticated client.
  Stream<List<ServiceBookingData?>> getAllBookingsClient() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final matchingBookings = bookingsCollection.where("clientID", isEqualTo: uid);
    return matchingBookings
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          ServiceBookingData.fromMap(doc)
      ).toList();
    });
  }
}
