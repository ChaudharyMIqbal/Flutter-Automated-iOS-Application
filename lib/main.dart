import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:camera/camera.dart';
import 'dart:core';
import 'package:start_flutter_app/widgets/dialog.dart';


List<CameraDescription> cameras;

void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
    print('in main file !!!!!!!!!!!!!!!');
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }

  runApp(MaterialApp(home: SplitApp()));

}

class SplitApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _SplitAppState createState() => _SplitAppState();

}

class _SplitAppState extends State<SplitApp> {
  //getting users email variables

  final String url = "http://192.168.100.11:3000/api/logs";
  List _notes;   //Individual notes for searching user
  List _notesForDisplay; //displaying all current users
  String selectedEmail = "";
  Map data; //decoding http get request
  bool isLoading;
  bool value = false;
  //getting battery,location variables
  var battery;
  var location;



  @override
  void initState(){
    super.initState();
    getData();
    print('in app');
  }
  //getting user emails
  Future getData() async {
    try {
      // http.Response response = await http.get(
      //     "http://192.168.18.45:3000/api/user/");

      var response = await http.get(
          Uri.encodeFull(url),

          headers: {"content-type": "application/json"});
      //print('after response');
      if (response.statusCode == 200) {
        data = json.decode(response.body);
        print('after decode');
        if(data["results"][0] != 0) {
          setState(() {
            _notes = data["results"];
            _notesForDisplay = _notes;
            isLoading = true;
            print('isLoading '+isLoading.toString());
          });
        }
        }
    }catch(e){
      setState(() {
        isLoading = false;
        print('isLoading '+isLoading.toString());
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff4FAEC8),
      appBar: AppBar(
        title: Center(child: Text("Connect with Admin")),
        backgroundColor: Color((0xff4FAEC8)),
      ),
      body: (isLoading == true) ? SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ListView.builder(
              itemCount: _notesForDisplay == null ? 1 : _notesForDisplay.length + 1,
              shrinkWrap: true ,
              itemBuilder: (BuildContext context, int index){
                return index == 0 ? _searchBar() :
                _buildCard(index-1);
              },
            ),
            SizedBox(height: 30.0,),
            refreshUsersData(),
          ],
        ),
      ) : (isLoading == false) ? Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
    child: Column(
      children: [
        Card(
        elevation: 10.0,
        margin: EdgeInsets.all(8.0),
        child: InkWell(
// highlightColor: Color(0xff4FAEC8),
        splashColor: Color(0xff4FAEC8),
        radius: 35.0,
        child: Container(
        height: 70.0,
        child: Center(child: Text('No Logged in user',style: TextStyle(
        color: Colors.grey.shade600,fontSize: 15.0,
        ),)),
        padding: EdgeInsets.all(20.0),
        ),
        ),
        ),
        SizedBox(height: 250.0,),
        refreshUsersData(),
      ],
    ),
    ): Center(child: CircularProgressIndicator(backgroundColor: Colors.white,)),
    );
  }
    refreshUsersData() {
    return Container(
        width: 200.0,
        height: 50.0,
        child: RaisedButton(
          elevation: 20.0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5)),
          child: Text('Refresh',style: TextStyle(
            color: Colors.grey.shade600,fontWeight: FontWeight.bold,
          ),),
          onPressed: () {
            setState(() {
              getData();
            });

          },
        ),
      );
  }


  //search bar implementation
  _searchBar(){
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: TextField(
              decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                    //borderRadius: BorderRadius.all(Radius.circular(8.0),),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                    //borderRadius: BorderRadius.all(Radius.circular(8.0),),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search . . .'
              ),
              onChanged: (value) {
                value = value.toLowerCase();
                setState(() {
                  _notesForDisplay = _notes.where((note) {
                    var noteEmail = note["user"]["email"].toLowerCase();
                    return noteEmail.contains(value);
                  }).toList();
                });
              },
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white,
          ),
        ],
      );
  }


  //listing users in card to generate request to admin on click on the emails
  _buildCard(index) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Card(
        elevation: 10.0,
        margin: EdgeInsets.all(8.0),
        child: InkWell(
          // highlightColor: Color(0xff4FAEC8),
          splashColor: Color(0xff4FAEC8),
          radius: 35.0,
          child: Container(
            height: 70.0,
            child: Center(child: Text(_notesForDisplay[index]["user"]["email"],style: TextStyle(
              color: Colors.grey.shade900,fontSize: 20.0,
            ),),),
            padding: EdgeInsets.all(20.0),
          ),
          onTap: () async{
            selectedEmail = _notesForDisplay[index]["user"]["email"];
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return DialogState(cameras,selectedEmail);
              },
            );
          },

        ),
      ),
    );
  }

}
