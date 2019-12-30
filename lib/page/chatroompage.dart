import 'package:bubble/bubble.dart';
import 'package:chatbar/chatbar.dart';
import 'package:chatbot/model/message.dart';
import 'package:chatbot/services/crud.dart';
import 'package:chatbot/utils/colors.dart';
import 'package:chatbot/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chat_bar/flutter_chat_bar.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatRoomPage extends StatefulWidget {
  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  List<Messages> messagesList;
  String userid;
  String _roomid;
  ChatBarState _chatBarState = ChatBarState.ACTIVE;
  int selectedMessageIndex = 1111111;
  bool isVisibileDelete = false;
  Color selectedItemColor = Colors.lightBlueAccent[200];
  Color defaultItemColor = Colors.white;
  Color selectedMessageItemColor;
  bool isWaitingVoice = false;
  TextEditingController messageTextFieldConstroller = TextEditingController();

  ScrollController _scrollController = new ScrollController();

  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  //SpeechTOText Var
  String lastWords = "";
  final SpeechToText speech = SpeechToText();
  bool _hasSpeech = false;
  bool _stressTest = false;
  int _stressLoops = 0;
  String lastError = "";
  String lastStatus = "";
  String _currentLocaleId = "";
  List<LocaleName> _localeNames = [];

  //TextToSpeech
  FlutterTts flutterTts = FlutterTts();


  @override
  void initState() {
    // TODO: implement initState
    messagesList = new List();
    super.initState();
    _roomid = CrudMethods().getPushKey();
    _initialize();
    initSpeechState();

  }

  _initialize() async {
    FirebaseUser user = await CrudMethods().getFirebaseUser();
    userid = user.uid;
    CrudMethods.myRef
        .child(Constants.refChatRoom + '/' + userid + '/messages')
        .orderByChild('endtime')
        .onChildAdded
        .listen(_onEntryAdded);
    CrudMethods.myRef
        .child(Constants.refChatRoom + '/' + userid + '/messages')
        .orderByChild('endtime')
        .onChildChanged
        .listen(_onEntryChanged);
    CrudMethods.myRef
        .child(Constants.refChatRoom + '/' + userid + '/messages')
        .orderByChild('endtime')
        .onChildRemoved
        .listen(_onEntryRemoved);
    setState(() {});
  }

  _controlStatus() {
    if (messagesList.length > 0 && messagesList.last.uid == userid) {
      _chatBarState = ChatBarState.TYPING;
    } else {
      _chatBarState = ChatBarState.ACTIVE;
    }
  }

  _onEntryRemoved(Event event) {
    var old = messagesList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      messagesList.removeAt(messagesList.indexOf(old));
      _controlStatus();
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      Messages message = Messages.fromSnapshot(event.snapshot);
      messagesList.add(message);
      _controlStatus();
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      if(isWaitingVoice == true && message.uid != CrudMethods.mUser.uid){
        _readTheMessage(message.message);
      }
    });
  }

  _onEntryChanged(Event event) {
    var old = messagesList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      messagesList[messagesList.indexOf(old)] =
          Messages.fromSnapshot(event.snapshot);
      _controlStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 55.0),
          child: FlareActor(
            'assets/flare/Tu_Background.flr',
            alignment: Alignment.center,
            fit: BoxFit.cover,
            animation: 'One',
          ),
        ),
        GestureDetector(
          onTap: () {
            _setVisibilityControlDeleteItem();
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: ChatBar(
              color: Color.fromRGBO(203, 152, 50, 100),
              height: 60.0,
              username: 'Trakya Universitesi Öğrenci İşleri',
              actions: <Widget>[
                _deleteActionItemWidget(),
              ],
              status: _chatBarState,
              profilePic:
                  'https://www.trakya.edu.tr/admin/tools/theme/www_v2/images/logo/tr/logo.png',
            ),
            body: SafeArea(
              child: Container(
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: 0.0,
                      bottom: 0.0,
                      left: 0.0,
                      right: 0.0,
                      child: Container(
                        color: Colors.black12,
                      ),
                    ),
                    Positioned(
                      top: 0.0,
                      bottom: 0.0,
                      right: 8.0,
                      left: 8.0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 60.0),
                        child: _messagesWidget(),
                      ),
                    ),
                    Positioned(
                        bottom: 8.0,
                        left: 16.0,
                        right: 16.0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: <Widget>[
                              _textFieldMessageWidget(),
                              Spacer(),
                              _voiceButton(),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _deleteActionItemWidget() {
    return Visibility(
      visible: isVisibileDelete,
      child: IconButton(
        onPressed: () {
          if (messagesList.length > 0 &&
              messagesList[selectedMessageIndex].uid == userid) {
            setState(() {
              CrudMethods().writeData(
                  null,
                  Constants.refChatRoom +
                      '/' +
                      userid +
                      '/messages/' +
                      messagesList[selectedMessageIndex].key);
              isVisibileDelete = false;
              selectedMessageIndex = 1111111;
            });
          }
        },
        icon: Icon(Icons.delete),
        color: Colors.white,
      ),
    );
  }

  _messagesWidget() {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: messagesList.length,
      itemBuilder: (BuildContext context, int index) {
        if (messagesList[index].uid == userid) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: GestureDetector(
              onLongPress: () {
                if (messagesList.length > 0 &&
                    messagesList[index].uid == userid) {
                  setState(() {
                    isVisibileDelete = true;
                    selectedMessageItemColor = selectedItemColor;
                    selectedMessageIndex = index;
                  });
                } else {
                  isVisibileDelete = false;
                }
              },
              child: Bubble(
                color: selectedMessageIndex == index
                    ? selectedItemColor
                    : defaultItemColor,
                stick: true,
                nip: BubbleNip.rightTop,
                alignment: Alignment.centerRight,
                child: Text(messagesList[index].message),
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Bubble(
              stick: true,
              nip: BubbleNip.leftTop,
              alignment: Alignment.centerLeft,
              child: Text(messagesList[index].message),
            ),
          );
        }
      },
    );
  }

  _setVisibilityControlDeleteItem() {
    if (isVisibileDelete) {
      setState(() {
        isVisibileDelete = false;
        selectedMessageItemColor = defaultItemColor;
        selectedMessageIndex = 1111111;
      });
    }
  }

  _textFieldMessageWidget() {
    return Padding(
      padding: const EdgeInsets.only(left:16.0,right: 8.0),
      child: GestureDetector(
        onTap: () {
          _setVisibilityControlDeleteItem();
        },
        child: Container(
          width: 280.0,
          child: Center(
            child: TextField(
              onTap: () {
                _setVisibilityControlDeleteItem();
              },
              controller: messageTextFieldConstroller,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              onSubmitted: (text) {
                _sendMessage(text);
              },
              onEditingComplete: () {},
              style: TextStyle(fontSize: 16.0, color: Colors.black),
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Bir mesaj yaz.',
                  hintStyle: TextStyle(color: Colors.grey)),
            ),
          ),
        ),
      ),
    );
  }

  _sendMessage(String text){
    if (text != null && text.length > 1) {
      Messages newMessage = Messages(
          userid, text, DateTime.now().millisecondsSinceEpoch);
      CrudMethods().writeData(
          newMessage.toJson(),
          Constants.refChatRoom +
              '/' +
              userid +
              '/messages/' +
              DateTime.now().millisecondsSinceEpoch.toString());
      setState(() {
        messageTextFieldConstroller.clear();
      });
    }
  }

  _voiceButton() {
    return Padding(
      padding: const EdgeInsets.only(right:16.0),
      child: GestureDetector(
        onTap: (){
          startListening();
        },
        child: Container(child: Icon(Icons.keyboard_voice),),
      ),
    );
  }

  void startListening() {
    lastWords = "";
    lastError = "";
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 10),
        localeId: _currentLocaleId);
    _showDialogFuncWithLoading('Şimdi Konuşun..');
    setState(() {});
  }

  _showDialogFuncWithLoading(String title) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.black12,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(title,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        });
  }


  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    _localeNames = await speech.locales();
    var systemLocale = await speech.systemLocale();
    _currentLocaleId = systemLocale.localeId;
    if (!mounted) return;
    setState(() {
      _hasSpeech = hasSpeech;
    });
  }
  void statusListener(String status) {
    changeStatusForStress(status);
    setState(() {
      lastStatus = "$status";
    });
  }

  void changeStatusForStress(String status) {
    if (!_stressTest) {
      return;
    }
    if (speech.isListening) {
      stopListening();
    } else {
      if (_stressLoops >= 100) {
        _stressTest = false;
        print("Stress test complete.");
        return;
      }
      print("Stress loop: $_stressLoops");
      ++_stressLoops;
      startListening();
    }
  }

  void stopListening() {
    speech.stop();
    setState(() {});
  }

  void cancelListening() {
    speech.cancel();
    setState(() {});
  }

  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = "${result.recognizedWords}";
      if(result.finalResult == true){
        messageTextFieldConstroller.text += lastWords + ' ';
        _sendMessage(messageTextFieldConstroller.text);
        messageTextFieldConstroller.text = '';
        isWaitingVoice = true;
        Navigator.pop(context);
        stopListening();
      }
    });
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

   _readTheMessage(String message) {
     FlutterTts flutterTts = FlutterTts();
     _speak(message);
   }

  Future _speak(String message) async{
    var result = await flutterTts.speak(message);
    //if (result == 1) setState(() => ttsState = TtsState.playing);
  }

  Future _stop() async{
    var result = await flutterTts.stop();
   // if (result == 1) setState(() => ttsState = TtsState.stopped);
  }
}
