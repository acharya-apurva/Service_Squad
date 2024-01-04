import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_interface.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getCurrentUserEmail() {
    return _auth.currentUser?.email ?? '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _showContactListDialog(context);
    });
  }

  String generateConversationId(String email1, String email2) {
  List<String> emails = [email1, email2];
  emails.sort(); // This sorts the list in place
  return emails.join("_");
}

  // Function to fetch conversations
  Stream<QuerySnapshot> _fetchConversations() {
    // Assuming there's a 'conversations' collection in Firestore
    // each conversation document has a 'messages' subcollection
    return _firestore.collection('conversations')
    .orderBy('latestMessage.timestamp', descending: true) // Make sure to update your data model to include this
    .snapshots();
  }

  // Function to start a chat
  Future<void> startChat(String currentUserEmail, String otherUserEmail) async {
  final conversationId = generateConversationId(currentUserEmail, otherUserEmail);
  
  // Reference to the conversation document
  DocumentReference conversationRef = _firestore.collection('conversations')
                                                  .doc(conversationId);

  // Check if the conversation already exists
  var conversationSnapshot = await conversationRef.get();
  if (!conversationSnapshot.exists) {
    // If the conversation does not exist, create a new one
    await conversationRef.set({
      'participants': [currentUserEmail, otherUserEmail],
    });
  }

  // Check if the widget is still mounted before navigating
  if (!mounted) return;

  // Navigate to the chat interface
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatInterface(conversationId: conversationId,otherUserEmail:otherUserEmail),
    ),
  );
}

  //  Provide a user-friendly way to select contacts or recent chats instead of typing emails
  void _showContactListDialog(BuildContext context) async {
  String currentUserEmail = getCurrentUserEmail();

  // Fetch conversations involving the current user
  QuerySnapshot conversationSnapshot = await _firestore.collection('conversations')
    .where('participants', arrayContains: currentUserEmail)
    .get();

  // Extract emails of other participants
  List<String> contacts = [];
  for (var doc in conversationSnapshot.docs) {
    var participants = List<String>.from(doc['participants']);
    participants.remove(currentUserEmail); // Remove current user's email
    contacts.addAll(participants); // Add other participants
  }

  // Remove duplicates
  contacts = contacts.toSet().toList();

  // Proceed to show dialog with the fetched contacts
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Select a Contact'),
        content: SingleChildScrollView(
          child: ListBody(
            children: contacts.map((contact) => ListTile(
              title: Text(contact),
              onTap: () {
                Navigator.of(context).pop();
                //ChatService.startChat(currentUserEmail, contact,context,_firestore);
                startChat(currentUserEmail, contact);
              },
            )).toList(),
          ),
        ),
      );
    },
  );
}


  Widget _buildContactsList() {
  return FutureBuilder<QuerySnapshot>(
    future: _firestore.collection('conversations')
      .where('participants', arrayContains: getCurrentUserEmail())
      .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }

      if (snapshot.hasError || !snapshot.hasData) {
        return Text('Error fetching contacts');
      }

      // Extract emails of other participants
      List<String> contacts = [];
      for (var doc in snapshot.data!.docs) {
        var participants = List<String>.from(doc['participants']);
        participants.remove(getCurrentUserEmail());
        contacts.addAll(participants);
      }

      // Remove duplicates
      contacts = contacts.toSet().toList();

      // Create a new list with marked current user
      String currentUserEmail = getCurrentUserEmail();
      List<String> modifiedContacts = contacts.map((contact) {
        return contact == currentUserEmail ? "$contact (Self)" : contact;
      }).toList();

      return ListView(
        children: modifiedContacts.map((contact) => ListTile(
          title: Text(contact),
          onTap: () {
           // Prevent starting a chat with self
            if (contact != currentUserEmail + " (Self)") {
              //ChatService.startChat(currentUserEmail, contact.replaceAll(" (Self)", ""),context,_firestore);
              startChat(currentUserEmail, contact.replaceAll(" (Self)", ""));
            }
          },
        )).toList(),
      );
    },
  );
}



  //create a list of chat items
  Widget _buildChatList() {
  return StreamBuilder<QuerySnapshot>(
    stream: _fetchConversations(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(), // Replace with user's avatar
              title: Text(data['participants'][1]), // Adjust based on your data model
              subtitle: Text(data['latestMessage']['text']), // Latest message snippet
              trailing: Text(data['latestMessage']['timestamp'].toDate().toString()), // Timestamp
              //onTap: () => ChatService.startChat(getCurrentUserEmail(), data['participants'][1],context,_firestore),
              onTap: () => startChat(getCurrentUserEmail(), data['participants'][1]),
            );
          },
        );
      } else {
        return CircularProgressIndicator();
      }
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white), // Set the color here
        backgroundColor: Colors.deepPurple,
        title: Center(
          child: Text("Messages",
              style: GoogleFonts.lilitaOne(
                color: Colors.white,
                fontSize: 48,
              )),
        ),
      ),
      
      body: _buildContactsList(),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showStartChatDialog(context);
        },
        child: Icon(Icons.message),
      ),
    );
  
  }

  void _showStartChatDialog(BuildContext context) {
  TextEditingController emailController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Start a new chat'),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(hintText: "Enter user's email"),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Start Chat'),
            onPressed: () {
              String currentUserEmail = getCurrentUserEmail();
              String otherUserEmail = emailController.text;

              if (otherUserEmail.isNotEmpty) {
                //ChatService.startChat(currentUserEmail, emailController.text,context,_firestore);
                startChat(currentUserEmail, emailController.text);
              }
              
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
  
}

class ChatService {
  static Future<void> startChat(
    String currentUserEmail, 
    String otherUserEmail,
    BuildContext context, 
    FirebaseFirestore firestore) async {
    final conversationId = generateConversationId(currentUserEmail, otherUserEmail);
  
  // Reference to the conversation document
  DocumentReference conversationRef = firestore.collection('conversations')
                                                  .doc(conversationId);
  print("CONVERSATIONID IS : ${conversationId}");
  print("conversationRef conversationRef IS : ${conversationRef.toString()}");
  // Check if the conversation already exists
  try {
    var conversationSnapshot = await conversationRef.get();
    print("conversationSnapshot conversationSnapshotconversationSnapshot:  ${conversationSnapshot.toString()}");
    print("Does conversationSnapshot exist? ${conversationSnapshot.exists}");
    if (!conversationSnapshot.exists) {
    // If the conversation does not exist, create a new one
    await conversationRef.set({
      'participants': [currentUserEmail, otherUserEmail],
    });

  }
  } catch (e) {
    if (e is FirebaseException){
      print('FirebaseException: ${e.code}, ${e.message}');
    }
    else {
      print('Other exception: ${e.toString()}');
    }
  }
  

  // Navigate to the chat interface
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatInterface(conversationId: conversationId,otherUserEmail:otherUserEmail),
    ),
  );
  }

  static String generateConversationId(String email1, String email2) {
  List<String> emails = [email1, email2];
  emails.sort(); // This sorts the list in place
  return emails.join("_");
  }
}