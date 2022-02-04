import 'package:flutter/material.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'dart:core';
import 'package:battery/battery.dart';
import '../objectdetection/home.dart';
import 'dart:io';

class DialogState extends StatefulWidget {
  final selectedEmail;
  final cameras;
  DialogState(this.cameras,this.selectedEmail);
  @override
  _DialogState createState() => _DialogState();
}
class _DialogState extends State<DialogState> {
  bool value = false;
  var battery;
  var location;
  Battery _battery = Battery();
  //socket initialization
  IO.Socket socket = IO.io('http://192.168.100.11:3000', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  },
  );

  @override
  void initState() {
    // TODO: implement initState
    print('in initState');
    super.initState();
    combineFunction(widget.selectedEmail);
    print('after combine function');
  }
  Future<bool> combineFunction(String email) async{
    battery = await  getBatteryLevel();
    location =  await getCurrentLocation();
    var soc = SocketData(location.latitude.toString(),location.longitude.toString(),battery.toString(),email);
    soc.printData();
    try {
      socket.connect();
      socket.emitWithAck('connection-request', soc, ack: (data) {
        print('ack $data');
        if (data != null) {
          print('from server $data');
          print('value before setState'+value.toString());
          setState(() {
            value = true;
          });
          print('value after setState'+value.toString());
        } else {
          print("Null");
        }
      });
    }catch(e){
      print('socket not accepted');
    }
    return value;
  }


  //user battery (current phone charging)
  getBatteryLevel() {
    print('getting battery');
    final batteryLevel = Platform.isIOS ?  80 : _battery.batteryLevel;
    return  batteryLevel;
  }
  //user current location
  getCurrentLocation(){
    print('getting location');
    final geoPosition = Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print('after getting location');
    return geoPosition;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 30.0,
      title: Text("Connecting with the admin"),
      content:value ?  Text('Proceed to new page') : Text('Waiting for response . . .'),
      actions: [
        FlatButton(onPressed: () {
          if(value) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomePage(widget.cameras, socket,widget.selectedEmail)),
            );
          }
        },
          child:
          Text('Proceed', style: TextStyle(
              color: value ? Color(0xff4FAEC8) : Colors.black26, fontSize: 20.0
          ),
          ),
        ),
      ],

    );
  }
}


//json conversion for object data
class SocketData{
  String latitude;
  String longitude;
  String battery;
  String email;
  SocketData(this.latitude,this.longitude,this.battery,this.email);

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'battery': battery,
      'email':email
    };
  }
  printData()
  {
    print(latitude);
    print(longitude);
    print(battery);
    print(email);
  }
}