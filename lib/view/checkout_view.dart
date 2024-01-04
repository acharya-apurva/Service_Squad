import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_squad/model/professional_service.dart';
import 'package:service_squad/model/service_booking_data.dart';

import '../controller/payment_controller.dart';
import '../model/checkout_cart.dart';
import 'message_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutView extends StatefulWidget {
  final ProfessionalService service;
  final ServiceBookingData booking;
  const CheckoutView({super.key, required this.service, required this.booking});
  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
 /* {
    checkoutCart = await PaymentService.getCheckoutCart(
        email: FirebaseAuth.instance.currentUser!.email!,
        serviceID: service.id!,
        bookingStart: booking.bookingStart.millisecondsSinceEpoch,
        bookingLength: booking.bookingLength,
        clientID: FirebaseAuth.instance.currentUser!.uid,
        address: booking.address,
    );
  }*/

  CheckoutCart? _checkoutCart;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  Future<void> loadCart() async {
    final result = await PaymentService.getCheckoutCart(
      email: FirebaseAuth.instance.currentUser!.email!,
      serviceID: widget.service.id!,
      bookingStart: widget.booking.bookingStart.millisecondsSinceEpoch,
      bookingLength: widget.booking.bookingLength,
      clientID: FirebaseAuth.instance.currentUser!.uid,
      address: widget.booking.address,
    );
    setState(() {
      _checkoutCart = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.white), // Set the color here
              backgroundColor: Colors.deepPurple,
              title: Text(
                  "Checkout",
                  style: GoogleFonts.lilitaOne(
                    color: Colors.white,
                    fontSize: 48.0,
                  )
              ),
            ),
            body: Column(
              // padding: EdgeInsets.all(12.0),
              children: [
                _checkoutCart != null ? Expanded(child: ListView.builder(
                  itemCount: _checkoutCart?.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _checkoutCart!.cartItems[index];
                    return createCheckoutItemWidget(item);
                  }
                  )) : const Text('Please wait...'),
                Text('Total: \$${_checkoutCart != null ? (_checkoutCart!.totalAmount / 100)?.toStringAsFixed(2) : "loading"}'),
                ElevatedButton(
                  child: Text("Proceed to pay"),
                  onPressed: _checkoutCart == null ? null : () async {

                    bool result = await PaymentService.payCheckoutCart(
                    checkoutCart: _checkoutCart!,
                    context: context,
                    );

                    if (result == true) {
                      setState(() {
                        _isLoading = true;
                      });
                      // Wait for booking item to be created in
                      //  service_bookings on firebase to confirm a payment.
                      final bookingDoc = await PaymentService.getBooking(_checkoutCart!.bookingID);
                      if (bookingDoc != null && bookingDoc.id == _checkoutCart!.bookingID) {

                        print("confirmed payment");
                        setState(() {
                          _isLoading = false;
                        });
                        // TODO: Handle confirmed payment here!
                        String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? "";
                        String? otherUserEmail = widget.service.email; // // // NEED TO GET ANOTHER GUYS'S EMAIL ///
                        if (otherUserEmail != null && otherUserEmail.isNotEmpty) {
                          await ChatService.startChat(currentUserEmail, otherUserEmail,context,FirebaseFirestore.instance);
                        }

                      } else {
                        print("unable to confirm payment");
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          if (_isLoading) const Opacity(
              opacity: 0.8,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          if (_isLoading) const Center(
              child: CircularProgressIndicator(),
            ),
        ],
    );
  }

  Widget createCheckoutItemWidget(CheckoutItem item) {

    return Column(
     children: [
       Card(
        margin: EdgeInsets.all(8.0),
        child: ListTile(
          title: Text("${item.name}: ${item.price.toStringAsFixed(2)}"),
          trailing: Text("x${item.quantity.toString()} = \$${(item.price * item.quantity).toStringAsFixed(2)}"),
        ),
      ),
     ]
    );
  }
}
