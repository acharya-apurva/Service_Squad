import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:service_squad/view/auth_gate.dart';
import 'controller/professional_service_controller.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Notification Service
  NotificationService notificationService = NotificationService();
  await notificationService.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.publishableKey = "pk_test_51OF3BFCRzhLSPD1XuoRlWUA0ae8YFEIi8QL2Ogj5Bh9VaAZH8N4kYi2samABXboL17xjA99E1EUpkko95iYOpUht005uAhPBn7";
  await Stripe.instance.applySettings();

  //Just for testing Phase
  // ProfessionalServiceController professionalServiceController = ProfessionalServiceController();
  // professionalServiceController.clearAllDocsInAllProfessionalServiceCollectionToDisplayToCustomers();
  // professionalServiceController.clearAllDocsInIndividualUserProfessionalServiceCollection();

  runApp(const MainApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

/** 
// Consolidated notification setup function
void setupNotification() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  if (Platform.isAndroid) {
    await _createNotificationChannel(flutterLocalNotificationsPlugin);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen(updateFcmTokenForUser);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      showForegroundNotification(message.notification!.title, message.notification!.body);
    }
  });
}
*/



void showForegroundNotification(String? title, String? body) {
  // Here, we are using the showDialog function to show a simple dialog.
  // You can replace this with your method of displaying a notification.
  showDialog(
    context: navigatorKey.currentContext!, // Make sure you have a navigatorKey
    builder: (_) => AlertDialog(
      title: Text(title ?? "New Message"),
      content: Text(body ?? "You have a new message."),
      actions: [
        TextButton(
          child: Text('Ok'),
          onPressed: () {
            Navigator.of(navigatorKey.currentContext!).pop(); // Close the dialog
          },
        ),
      ],
    ),
  );
}

//=====till here=====


class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    setupInteractedMessage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const AuthGate(),
      routes: {
        '/chat': (context) => ChatScreen(), // Replace with your actual chat screen widget
      },
      // Include other properties as needed
    );
  }

  Future<void> setupInteractedMessage() async {
    // Handle messages that opened the app from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle messages that opened the app from a background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
  if (message.data['type'] == 'chat') {
    // Assuming you're using named routes
    Navigator.of(context).pushNamed(
      '/chat',
      arguments: ChatArguments(message),
    );
  }
}

}


class ChatArguments {
  final RemoteMessage message;

  ChatArguments(this.message);
}

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ChatArguments args = ModalRoute.of(context)!.settings.arguments as ChatArguments;
    RemoteMessage message = args.message;

    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Text("Chat message: ${message.data['message']}"), // Example usage
    );
  }
}


class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notification permitted');

      // Initialize local notifications
      var initializationSettingsAndroid = AndroidInitializationSettings('@android:drawable/ic_dialog_alert');
      var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      // Listen for FCM messages when the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('remote msg msg msg ... ${message}');
        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });

      // Listen for FCM token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen(updateFcmTokenForUser);
      print('listen FCM token refresh');
    } 
    else {
      print('User declined or has not accepted permission');
    }


  }


  Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages',  // ID of the channel, decide by self
    'Chat Messages', // Title of the channel
    description: 'Notifications for new chat messages and conversations.', // Description of the channel
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  print('_createNotificationChannel _createNotificationChannel');
}

  Future<void> updateFcmTokenForUser(String newToken) async {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': newToken,
    });
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    // Call the method to update the token
    updateFcmTokenForUser(newToken); // Make sure to define this method
  });
  }


  void _showLocalNotification(RemoteMessage message) {
    var androidDetails = const AndroidNotificationDetails(
      'channelId',
      'channelName',
      channelDescription: 'channelDescription',
      importance: Importance.max,
      priority: Priority.high,
    );

    var generalNotificationDetails = NotificationDetails(android: androidDetails);

    flutterLocalNotificationsPlugin.show(
      0,
      message.notification!.title,
      message.notification!.body,
      generalNotificationDetails,
    );
  }
}