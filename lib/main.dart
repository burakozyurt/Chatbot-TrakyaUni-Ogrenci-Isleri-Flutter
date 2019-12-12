import 'package:chatbot/page/chatroompage.dart';
import 'package:chatbot/page/homepage.dart';
import 'package:chatbot/services/crud.dart';
import 'package:chatbot/utils/loader1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey<NavigatorState> navKey = new GlobalKey<NavigatorState>();
  Widget firstPage;
  FirebaseUser firebaseUser;
  @override
  void initState() {
    // TODO: implement initState
    firstPage = ChatRoomPage();
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if(user != null){
      firebaseUser = user;
      setState(() {

      });
    }else{
      firebaseUser = await CrudMethods().signInAnonymously();
      setState(() {

      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _router();
  }

  _router(){
    if(firebaseUser == null){
      return new MaterialApp(home: Scaffold(body: Container(color:Colors.white,child: Center(child: Loader()),)));
    }else{
      return new MaterialApp(
          navigatorKey: navKey,
          home: firstPage,
          theme: ThemeData(
            fontFamily: 'Comfortaa',
          ),
          routes: <String, WidgetBuilder>{
            '/homepage': (BuildContext context) => new HomePage(),
            '/chatroompage': (BuildContext context) => new ChatRoomPage(),
          });
    }
  }
}
