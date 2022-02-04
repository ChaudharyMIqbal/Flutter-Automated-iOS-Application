import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import 'dart:async';
import 'camera.dart';
import 'models.dart';
import 'bndbox.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  IO.Socket socket;
  final selectedEmail;
  HomePage(this.cameras,this.socket,this.selectedEmail);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const duration = const Duration(seconds: 1);
  String onTapImageValue;
  int counterr = 0;
  int secondsPassed = 0;
  bool isActive = false;
  String value;

  @override
  void initState(){
    super.initState();
    openCameraRequest();
    print('in app');
  }

  //stopwatch variables
  Timer timer;
  int seconds;
  int minutes;
  int hours;
  void handleTick() {
    if (isActive) {
      setState(() {
        secondsPassed = secondsPassed + 1;
      });
    }
  }
  String onSelectImage(int index){
    print('printing image index');
   print(index);
   if(index == 0 || index == 3 || index == 6) {
     onTapImageValue = 'cup';
     return 'cup';
   }
   else if(index == 1 || index == 4 || index == 7)
     onTapImageValue = 'mouse';
   else if(index == 2 || index == 5 || index == 8)
     onTapImageValue = 'glass';
  return onTapImageValue;
  }


  void objectGone() {
    List<String>  t = [hours.toString().padLeft(2, '0'), minutes.toString().padLeft(2, '0'), seconds.toString().padLeft(2, '0')];
    String time = t.join(" ");
    //print('total time ' +time);
    widget.socket.emit('update-device', time);

  }

  void changeInAccuracy(String accuracy)
  {
    print('accuracy'+accuracy * 100);
    widget.socket.emit('event-accuracy',accuracy);
    counterr = 0;
  }
  void connectionDisconnected(){
    widget.socket.emit('disconnect', widget.selectedEmail);
  }
  Future<bool> openCameraRequest() async{
    print('in combine request 1');
     widget.socket.on('start-camera', (msg){
       value = msg;

     if(value == 'Hi'  && onTapImageValue != null)
       {
         onSelect(ssd);
         startTimerRequest();
       }
     else if (value == 'Hi' && onTapImageValue == null)
       {
         showDialog(context: context,
         builder: (BuildContext context){
           return AlertDialog(
             title: Text('Please select image to move forward'),
             actions: [
               FlatButton(onPressed: (){Navigator.pop(context);}, child: Text('Ok')),
             ],
           );

         });
       }

    });
    print('in combine request 2');
    return null;
  }
  Future<bool> startTimerRequest() async{
    await widget.socket.on('start-timer', (_){
      print('start timer');
      setState(() {
        isActive = !isActive;
      });

    });
  }

  void updateDevice()
  {
    print('object selected');
    var objData = ObjectData(onTapImageValue, widget.socket.id);
    print(objData.printData());
    widget.socket.emit('update-device', objData);
  }

  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  String _model = "";
  var nextframe = [];
  var oldFrame = [];
  List<int> frames = [];
  int counter = 0;
  int selectedCard = -1;

  loadModel() async {
    String res;
    switch (_model) {
      case yolo:
        res = await Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt",
        );
        break;

      case mobilenet:
        res = await Tflite.loadModel(
            model: "assets/mobilenet_v1_1.0_224.tflite",
            labels: "assets/mobilenet_v1_1.0_224.txt");
        break;

      case posenet:
        res = await Tflite.loadModel(
            model: "assets/posenet_mv1_075_float_from_checkpoints.tflite");
        break;

      default:
        res = await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt");
    }
  }

  onSelect(model) {
    setState(() {
      _model = model;

    });
    loadModel();
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    print('in main file !!!!!!!!!!!!!!!4');
    nextframe = recognitions
        .where((i) =>
            i['detectedClass'] == '$onTapImageValue' && i['confidenceInClass'] > 0.50)
        .toList();

    if(nextframe.length != 0) {
      if(counterr == 60)
        {
          changeInAccuracy(nextframe[0]['confidenceInClass'].toString());
        }
      frames.add(1);
    } else {
      frames.add(0);
    }
    counter++;
    print('counter'+counter.toString());
    print('frames length'+ frames.length.toString());

    print('frames'+frames.toString());
    if (frames.asMap().containsKey(counter - 2)) {
      print("Checking");
      int old = frames[counter - 2];
      int n = frames[counter - 1];
      if (old == 1 && n == 1) {
        print("Object in view");
      } else if (old == 1 && n == 0) {
        isActive = false;
        print("Object Gone");
        //emiting object gone message to server/admin
        objectGone();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("GATE CROSSED"),
              content: Container(
                height: 100.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Racer has crossed the gate"),
                    SizedBox(
                      height: 5.0,
                    ),
                    Text('Time: '+hours.toString().padLeft(2, '0')  + ': ' + minutes.toString().padLeft(2, '0') + ': ' + seconds.toString().padLeft(2, '0')),
                  ],
                ),
              ),
        );
      },
        );
      }
    } else {
      print("Initial Frame");
    }
    setState(() {
      counterr++;
      _recognitions = recognitions;
      print('recognitions ' +_recognitions.toString());
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }
  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Are you sure?'),
        content: new Text('Do you want to disconnect connection.'),
        actions: <Widget>[
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:    Text('NO', style: TextStyle(
                color:Color(0xff4FAEC8), fontSize: 20.0
            ),
            ),
          ),
          new FlatButton(
            onPressed: () {
              connectionDisconnected();
              Navigator.of(context).pop(true);
            },
            child:Text('YES', style: TextStyle(
                color:Color(0xff4FAEC8), fontSize: 20.0
            ),
            ),
          ),
        ],
      ),
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = [
      "assets/cup.png",
      "assets/mouse.png",
      "assets/glass.png",
      "assets/cup.png",
      "assets/mouse.png",
      "assets/glass.png",
      "assets/cup.png",
      "assets/mouse.png",
      "assets/glass.png",
    ];
    final mediaQueryData = MediaQuery.of(context);
    if (timer == null) {
      timer = Timer.periodic(duration, (Timer t) {
        handleTick();
      });
    }
    seconds = secondsPassed % 60;
    minutes = secondsPassed ~/ 60;
    hours = secondsPassed ~/ (60 * 60);
    print(hours);
    print(minutes);
    print(seconds);



    Size screen = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar:AppBar(
          title: Center(child: Text('Select item to detect')),
          backgroundColor: Color((0xff4FAEC8)),
        ),
        backgroundColor: Color(0xff4FAEC8),
        body: _model == ""
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 10.0,
                    ),
                    Expanded(
                      child: GridView.builder(
                        itemCount: images.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                           crossAxisSpacing: 2.0,
                           mainAxisSpacing: 2.0,
                        ),
                        itemBuilder: ( context,index) {
                          return InkWell(
                            splashColor: Color(0xff4FAEC8),
                            radius: 35.0,
                            onTap: (){
                              String text = onSelectImage(index);
                              setState(() {
                                selectedCard = index;
                                Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text(text.toUpperCase()+' selected'),),);
                                updateDevice();
                                if(value == 'Hi' && onTapImageValue != null )
                                  {
                                    onSelect(ssd);
                                  }
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.fromLTRB(7, 0, 7, 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: selectedCard == index ? Colors.white : Color(0xff4FAEC8),
                              ),
                              child: Card(
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                shadowColor: Colors.lightBlueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 20.0,
                                margin: EdgeInsets.all(8.0),
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.asset(images[index],
                                      ),
                                  ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Camera(
                    widget.cameras,
                    _model,
                    setRecognitions,
                  ),
                  BndBox(
                      _recognitions == null ? [] : _recognitions,
                      math.max(_imageHeight, _imageWidth),
                      math.min(_imageHeight, _imageWidth),
                      screen.height,
                      screen.width,
                      _model),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      margin: EdgeInsets.all(15.0),
                      color:Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          LabelText(
                              label: 'HRS', value: hours.toString().padLeft(2, '0')),
                          LabelText(
                              label: 'MIN',
                              value: minutes.toString().padLeft(2, '0')),
                          LabelText(
                              label: 'SEC',
                              value: seconds.toString().padLeft(2, '0')),
                        ],
                      ),
                    ),
                  ),
                  // Positioned(
                  //   bottom: 0,
                  //   right:0,
                  //   child: Container(
                  //     margin: EdgeInsets.all(20.0),
                  //     child: Row(
                  //       children: <Widget>[
                  //         Container(
                  //           width: 75,
                  //           height: 40,
                  //           margin: EdgeInsets.only(top: 30),
                  //           child: RaisedButton(
                  //             color: Colors.transparent,
                  //             shape: RoundedRectangleBorder(
                  //                 borderRadius: BorderRadius.circular(20)),
                  //             child: Text(isActive ? 'STOP' : 'START',style: TextStyle(
                  //               color: Colors.white,
                  //             ),),
                  //             onPressed: () {
                  //               setState(() {
                  //                 isActive = !isActive;
                  //               });
                  //             },
                  //           ),
                  //         ),
                  //         SizedBox(width: 10.0),
                  //         Container(
                  //           width: 75,
                  //           height: 40,
                  //           margin: EdgeInsets.only(top: 30),
                  //           child: RaisedButton(
                  //             color: Colors.transparent,
                  //             shape: RoundedRectangleBorder(
                  //                 borderRadius: BorderRadius.circular(20)),
                  //             child: Text('Reset',style: TextStyle(
                  //               color: Colors.white,fontWeight: FontWeight.bold,
                  //             ),),
                  //             onPressed: () {
                  //               setState(() {
                  //                 secondsPassed = 0;
                  //               });
                  //             },
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //
                  //   ),
                  // ),
                ],
              ),
      ),
    );
  }
}



class LabelText extends StatelessWidget {
  LabelText({this.label, this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color:Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$value',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '$label',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class ObjectData{
  String object;
  String id;

  ObjectData(this.object,this.id);

  Map<String, dynamic> toJson() {
    return {
      'object': object,
      'id': id,
    };
  }
  printData()
  {
    print('selected image :'+ object);
    print('socket id :'+ id);
  }
}