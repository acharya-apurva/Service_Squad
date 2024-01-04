import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'package:firebase_storage/firebase_storage.dart';

class ChatInterface extends StatefulWidget {
  final String conversationId;
  final String otherUserEmail;

  ChatInterface({required this.conversationId,required this.otherUserEmail});

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> _chatStream() {
    return _firestore.collection('conversations')
      .doc(widget.conversationId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    String currentUserEmail = getCurrentUserEmail(); 

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white), // Set the color here
        backgroundColor: Colors.deepPurple,
        title: Center(
          child: Text('${widget.otherUserEmail}',
              style: GoogleFonts.lilitaOne(
                color: Colors.white,
                fontSize: 48,
              )),
        ),
      ),
      // appBar: AppBar(title: Text('Chat with ${widget.otherUserEmail}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }


                return ListView(
                  reverse: true,
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                    return _messageTile(data['text'], data['imageUrl'], data['sender'] == currentUserEmail);
                  }).toList(),
                );

                // return ListView(
                //   reverse: true,
                //   children: snapshot.data!.docs.map((DocumentSnapshot document) {
                //     Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                //     bool isCurrentUser = data['sender'] == currentUserEmail;

                //     return _messageTile(data['text'], isCurrentUser);
                //   }).toList(),
                // );
              },
            ),
          ),
          _sendMessageArea(),
        ],
      ),
    );
  }


  Widget _messageTile(String message, String? imageUrl,bool isCurrentUser) {

  // Calculate the image size
  double maxWidth = MediaQuery.of(context).size.width / 3;
  double maxHeight = MediaQuery.of(context).size.height / 4;

  return Container(
    alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: Column(
      crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (imageUrl != null)
        GestureDetector(
          onTap: () => _showFullSizeImage(imageUrl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,),
            child: Image.network(imageUrl, fit: BoxFit.cover,)
          ), // Display the image
          ),
          
        if (message.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.grey[300],
              borderRadius: isCurrentUser
                  ? BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                      topRight: Radius.circular(15))
                  : BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                      topLeft: Radius.circular(15)),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
      ],
    ),
  );
}


  void _showFullSizeImage(String imageUrl) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      child: InteractiveViewer( // Allows pinch-to-zoom
        child: Image.network(imageUrl),
      ),
    ),
  );
  }

  Widget _sendMessageArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
          icon: Icon(Icons.photo),
          onPressed: _sendImage, // Call _sendImage method when this button is pressed
        ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration.collapsed(hintText: 'Send a message...'),
              textInputAction: TextInputAction.send, // Set the action button to 'Send'
              onSubmitted: (value) {
              _sendMessage(); // Call send message method when Enter is pressed
            },
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage({String? imageUrl}) async {
  if (_messageController.text.isNotEmpty || imageUrl != null) {
    // Reference to the conversation's messages
    CollectionReference messagesRef = _firestore.collection('conversations')
                                                 .doc(widget.conversationId)
                                                 .collection('messages');

    // Add a new message
    messagesRef.add({
      'text': _messageController.text,
      'imageUrl': imageUrl, // Image URL (can be null)
      'sender': getCurrentUserEmail(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    String recipientEmail = widget.otherUserEmail; // Replace with actual recipient's email
    String? recipientToken = await getRecipientFcmToken(recipientEmail);
    print('Start PUSHMSG Start PUSHMSG Start PUSHMSGStart PUSHMSG Start PUSHMSG ${recipientToken}');

    if (recipientToken != null) {
      // Send a push notification to the recipient
      print('Start PUSHMSG Start PUSHMSG Start PUSHMSGStart PUSHMSG Start PUSHMSG');
      sendPushMessage(recipientToken, _messageController.text);
    }
    _messageController.clear();
  }
}

Future<void> _sendImage() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    // Upload image to Firebase Storage and get the URL
    String imageUrl = await uploadImageToFirebaseStorage(File(pickedFile.path));
    _sendMessage(imageUrl: imageUrl);
  }
}

Future<String> uploadImageToFirebaseStorage(File imageFile) async {
  
  // Create a unique file name for the image
  String fileName = '${DateTime.now().millisecondsSinceEpoch}_${Path.basename(imageFile.path)}';

  // Create a reference to the Firebase Storage bucket
  Reference storageReference = FirebaseStorage.instance.ref().child('chat_images/$fileName');

  // Upload the file to Firebase Storage
  UploadTask uploadTask = storageReference.putFile(imageFile);

  // Wait for the upload to complete
  TaskSnapshot snapshot = await uploadTask;

  // Get the URL of the uploaded image
  String imageUrl = await snapshot.ref.getDownloadURL();

  return imageUrl;
}

void sendPushMessage(String token, String message) async {
  String severKey = 'AAAAHRFn8ko:APA91bHhCeKr55wt6v1XnNiS0GVbs6KNu5UcRHfoHGwlD5ixeS4BwoJZxTmX_ZSk7pz5i1wYAdSVPYwrgDDimTfsPNuCfzd6wHS0unmckbOLamOQJwe08fuX-bb9haM2PPJgMZcq9zoT';
  try {
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$severKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'body': message,
          'title': 'New Message'
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'id': '1',
          'status': 'done'
        }
      }),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  } catch (e) {
    print('Error sending push notification: $e');
  }
}

  String getCurrentUserEmail() {
    return _auth.currentUser?.email ?? '';
  }

  Future<String?> getRecipientFcmToken(String recipientEmail) async {
  try {
    var userDoc = await _firestore.collection('users').where('email', isEqualTo: recipientEmail).get();
    if (userDoc.docs.isNotEmpty) {
      return userDoc.docs.first.data()['fcmToken'];
    }
    return null;
  } catch (e) {
    print('Error fetching FCM token: $e');
    return null;
  }
}


  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
