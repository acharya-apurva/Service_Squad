
class CheckoutCart {

/*
paymentIntent: paymentIntent.client_secret,
            ephemeralKey: ephemeralKey.secret,
            customer: customerId,
            checkoutItems: {
                item: {
                    name: 'wage',
                    quantity: bookingLength / 2,
                    price: wage,
                },
            },
            total_amount: amount,
            success: true,
 */

  late String clientSecret;
  late String ephemeralKey;
  late String stripeCustomerID;
  List<CheckoutItem> cartItems = [];
  late int totalAmount;
  late String bookingID;

  CheckoutCart(dynamic json) {
    clientSecret = json['paymentIntent'];
    ephemeralKey = json['ephemeralKey'];
    stripeCustomerID = json['customer'];
    for (final item in json['checkoutItems']) {

      String name = item['name'];
      double quantity = item['quantity'].toDouble();
      double price = item['price'].toDouble();
      cartItems.add(CheckoutItem(
          name: name,
          quantity: quantity,
          price: price,
      ));
    }
    totalAmount = json['total_amount'];
    bookingID = json['bookingID'];
  }
}

class CheckoutItem {
  String name;
  double quantity;
  double price;
  CheckoutItem({
    required this.name,
    required this.quantity,
    required this.price
  });
}
