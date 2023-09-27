import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatefulWidget {
  final CameraDescription camera;

  MyApp({required this.camera});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String myString = 'HELLO';

  void updateString(String str) {
    setState(() {
      if (str=="Space"){
        myString+=" ";
      }
      else{
        myString += str;
      } 
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      _controller.setFlashMode(FlashMode.off); // Turn off the flash
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureAndSendImage() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();
      // final bytes = await image.readAsBytes();
      // final base64Image = base64Encode(bytes);

      // final response = await http.post(
      //   Uri.parse('http://127.0.0.1:5000/predict'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'image': base64Image}),
      // );

      final imageFile = File(image.path);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.121:5000/predict'),
    );

    // request.headers['Connection'] = "keep-alive";

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
        filename: path.basename(imageFile.path),
      ),
    );
    try {
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Process the response received from the server
        print(jsonResponse['label']);
        updateString(jsonResponse['label']);
      }
    } catch (e) {
      print('Error sending : $e');
    }

    
    } catch (e) {
      print('Error : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('SIGN READER',style: TextStyle(fontWeight: FontWeight.bold),)),
        
        body: Column(
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
            SizedBox(
                //Use of SizedBox
                height: 15,
              ),
          Container(
            padding: EdgeInsets.all(16.0), // Add padding around the text
            decoration: BoxDecoration(
              color: Colors.blue, // Add background color
              borderRadius: BorderRadius.circular(8.0), // Add rounded corners
            ),
            child: Text(
              'String: $myString',
              style: TextStyle(
                color: Colors.white, // Add text color
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
            
            SizedBox(
                //Use of SizedBox
                height: 20,
              ),
          FloatingActionButton(
          child: const Icon(Icons.camera),
          onPressed: _captureAndSendImage,
        ),
        
          
          ],
        ),
        floatingActionButton: ElevatedButton(
          child: Text('Refresh'),
          style: ElevatedButton.styleFrom(
            primary: Colors.blue,
          ),
          onPressed: () {setState(() {
      myString=""; 
    });},
        ),
        
      ),
    );
  }
}
