import 'package:chatbot/page/chatroompage.dart';
import 'package:chatbot/page/homepage.dart';
import 'package:chatbot/services/crud.dart';
import 'package:chatbot/utils/constants.dart';
import 'package:chatbot/utils/loader1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey<NavigatorState> navKey = new GlobalKey<NavigatorState>();
  Widget firstPage;
  FirebaseUser firebaseUser;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();



  @override
  void initState() {
    // TODO: implement initState
    firstPage = ChatRoomPage();
    super.initState();
    initialize();
    _fcmInit();
  }
  _fcmInit(){
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) {
        print('on launch $message');
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    
  }

  Future<void> initialize() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if(user != null){
      firebaseUser = user;
      setState(() {

      });
    }else{
      firebaseUser = await CrudMethods().signInAnonymouslyWithToken();
      setState(() {

      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
