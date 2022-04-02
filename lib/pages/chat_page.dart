import 'dart:io';

import 'package:chat_flutter/widgets/chat_message.dart';
import 'package:chat_flutter/widgets/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  User? _currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;

  Future<User?> _getUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      return user;
    } catch (e) {
      return null;
    }
  }

  void _sendMessage({String? text, File? imgFile}) async {
    final User? user = await _getUser();

    if (user == null) {
      _scaffoldKey.currentState!.showSnackBar(
        SnackBar(
          content: Text("Não foi possível fazer o login. Tente Novamente"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    Map<String, dynamic> data = {
      "uuid": user.uid,
      "senderName": user.displayName,
      "senderPhotoUrl": user.photoURL,
      "time": Timestamp.now(),
    };

    if (imgFile != null) {
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child(user.uid + DateTime.now().microsecondsSinceEpoch.toString())
          .putFile(imgFile);

      setState(() {
        _isLoading = true;
      });

      var url = await (await task).ref.getDownloadURL();
      data['imgUrl'] = url.toString();
      data['text'] = null;

      setState(() {
        _isLoading = false;
      });
    }

    if (text != null) {
      data['text'] = text;
      data['imgUrl'] = null;
    }

    FirebaseFirestore.instance.collection("messages").add(data);
  }

  @override
  void initState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_currentUser != null
            ? "Olá, ${_currentUser!.displayName}"
            : "Chat app flutter"),
        centerTitle: true,
        elevation: 0,
        actions: [
          _currentUser != null
              ? IconButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();

                    _scaffoldKey.currentState!.showSnackBar(
                      SnackBar(
                        content: Text("Deslogado com sucesso!"),
                      ),
                    );
                  },
                  icon: Icon(Icons.exit_to_app),
                )
              : Container()
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              //stream me retorna sempre que houver modificação
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("messages")
                    .orderBy("time")
                    .snapshots(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    default:
                      List<DocumentSnapshot> documents =
                          snapshot.data!.docs.reversed.toList();

                      return ListView.builder(
                        reverse: true,
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          return ChatMessage(
                            data: documents[index],
                            mine: documents[index]['uuid'] == _currentUser?.uid,
                          );
                        },
                      );
                  }
                },
              ),
            ),
            _isLoading ? LinearProgressIndicator() : Container(),
            TextComposer(sendMessage: _sendMessage),
          ],
        ),
      ),
    );
  }
}
