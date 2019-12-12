import 'package:firebase_database/firebase_database.dart';

class Messages{
  String _key;
  String _uid;
  String _message;
  int _endtime;

  Messages(this._uid, this._message, this._endtime);

  Messages.empty();

  Messages.dynamicval(dynamic v){
    this._uid = v['uid'];
    this._message = v['message'];
    this._endtime = v['endtime'];
  }

  Messages.fromSnapshot(DataSnapshot snapshot)
      : _key = snapshot.key,
        _uid = snapshot.value['uid'],
        _message = snapshot.value["message"],
        _endtime= snapshot.value["endtime"];

  toJson(){
    return {
      "uid": _uid,
      "message": _message,
      "endtime": _endtime,
    };
  }


  String get key => _key;

  set key(String value) {
    _key = value;
  }

  int get endtime => _endtime;

  set endtime(int value) {
    _endtime = value;
  }

  String get message => _message;

  set message(String value) {
    _message = value;
  }

  String get uid => _uid;

  set uid(String value) {
    _uid = value;
  }


}