import 'dart:async';

import 'package:chatbot/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class CrudMethods {
  static final FirebaseAuth mAuth = FirebaseAuth.instance;
  static FirebaseUser mUser;
  static FirebaseDatabase database = new FirebaseDatabase();
  static DatabaseReference myRef = database.reference();
  static String uid;

  CrudMethods() {
    mAuth.currentUser().then((user) {
      if (user != null) {
        uid = user.uid;
        mUser = user;
      }
    });
  }

  Future<FirebaseUser> signInAnonymously()async{
    bool isLogged = await isLoggedIn();
    if(isLogged){
      FirebaseUser user = await FirebaseAuth.instance.currentUser();
      return user;
    }else{
      AuthResult result = await mAuth.signInAnonymously();
      FirebaseUser user = result.user;
      writeData(true, Constants.refUser + '/' +user.uid);
      return user;
    }
  }

  Future<FirebaseUser> signInAnonymouslyWithToken()async{
    FirebaseMessaging _messaging = FirebaseMessaging();
    String token = await _messaging.getToken();
    bool isLogged = await isLoggedIn();
    if(isLogged){
      FirebaseUser user = await FirebaseAuth.instance.currentUser();
      return user;
    }else{
      AuthResult result = await mAuth.signInAnonymously();
      FirebaseUser user = result.user;
      writeData(token, Constants.refUser + '/' +user.uid);
      return user;
    }
  }

  Future<FirebaseUser> getFirebaseUser() async {
    mUser = await mAuth.currentUser();
    return mUser;
  }

  Future<bool> isLoggedIn() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> writeData(model, childRef) async {
    myRef.child(childRef).set(model).catchError((e) {
      print(e);
    });
  }
  Future<void> writeDataPush(model, childRef) async {
    myRef.child(childRef).push().set(model).catchError((e) {
      print(e);
    });
  }

  Future<DataSnapshot> readData(childRef) async {
    DataSnapshot snapshot = await myRef.child(childRef).once();
    return snapshot;
  }

  Stream<DataSnapshot> readDataStream(childRef){
    Stream snapshot = myRef.child(childRef).onValue;

    return snapshot;
  }

  String getPushKey() {
    return myRef.push().key;
  }
}
