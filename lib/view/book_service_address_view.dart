import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_squad/model/professional_service.dart';
import 'package:service_squad/model/service_booking_data.dart';

import 'checkout_view.dart';

class BookServiceAddressView extends StatefulWidget {
  final ProfessionalService service;
  final DateTime bookingStart;
  final int bookingLength;
  const BookServiceAddressView({super.key,
    required this.service,
    required this.bookingStart,
    required this.bookingLength});

  @override
  State<BookServiceAddressView> createState() => _BookServiceAddressViewState();
}

class _BookServiceAddressViewState extends State<BookServiceAddressView> {

  TextEditingController addr1Controller = TextEditingController();
  TextEditingController addr2Controller = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController provinceController = TextEditingController();
  TextEditingController postalCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white), // Set the color here
        backgroundColor: Colors.deepPurple,
        title: Center(child:Text(
            "Book Service",
            style: GoogleFonts.lilitaOne(
              color: Colors.white,
              fontSize: 48.0,
            )
        ),
      ),),
      // todo: add scrollable
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: addr1Controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: false,
                labelText: "Address line 1",

              ),

            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: addr2Controller,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Address line 2"
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: cityController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "City"
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: provinceController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Province"
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              String address = "${addr1Controller.text}, ${addr2Controller.text}, ${cityController.text}, ${provinceController.text}";
              final bookingData = ServiceBookingData(
                  serviceID: widget.service.id!,
                  bookingStart: widget.bookingStart,
                  bookingLength: widget.bookingLength,
                  dateCreated: DateTime.now(),
                  clientID: FirebaseAuth.instance.currentUser!.uid,
                  address: address
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        CheckoutView(service: widget.service, booking: bookingData,)
                )
              );
            },
            label: const Text("Proceed to checkout"),
            icon: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
