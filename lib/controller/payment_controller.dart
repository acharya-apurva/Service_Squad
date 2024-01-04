import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../model/checkout_cart.dart';

class PaymentService {

  static Future<CheckoutCart> getCheckoutCart({
    required String email,
    required String serviceID,
    required int bookingStart,
    required int bookingLength,
    required String clientID,
    required String address,
  }) async {
    final response = await http.post(
        Uri.parse(
            "https://stripepaymentintentrequest-efzsfkqsqa-uc.a.run.app/stripePaymentIntentRequest"),
        body: {
          'email': email,
          'serviceID': serviceID,
          'startEpoch': bookingStart.toString(),
          'bookingLength': bookingLength.toString(),
          'clientID': clientID,
          'address': address,
        }
    );

    final jsonResponse = jsonDecode(response.body);
    return CheckoutCart(jsonResponse);
  }

  static Future<bool> payCheckoutCart({
    required CheckoutCart checkoutCart,
    required BuildContext context,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: checkoutCart.clientSecret,
            merchantDisplayName: "Service Squad",
            customerId: checkoutCart.stripeCustomerID,
            customerEphemeralKeySecret: checkoutCart.ephemeralKey
        ),
      );

      print("initialized payment sheet");

      await Stripe.instance.presentPaymentSheet();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment was successful'))
      );

      return true;
    } catch (error) {
      if (error is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error occurred ${error.error.localizedMessage}'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error occurred $error'))
        );
      }
    }
    return false;
  }

  static Future<DocumentSnapshot?> getBooking(String bookingID) async {
    final stream = FirebaseFirestore.instance.doc("service_bookings/$bookingID").snapshots();
    await for (final doc in stream) {
      if (doc.id == bookingID && doc.data() != null) {
        return doc;
      }
    }
    return null;
  }

}