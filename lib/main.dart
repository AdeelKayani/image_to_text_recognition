import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:text_recognition/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool textScanning = false;
  XFile? imageFile;
  String scannedText = "";

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          textScanning = true;
          imageFile = pickedImage;
        });
        getRecognisedText(pickedImage);
      }
    } catch (e) {
      setState(() {
        textScanning = false;
        imageFile = null;
        scannedText = "Error occurred while scanning";
      });
    }
  }

  void getRecognisedText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textDetector = GoogleMlKit.vision.textDetector();

    try {
      RecognisedText recognisedText =
          await textDetector.processImage(inputImage);
      await textDetector.close();

      setState(() {
        scannedText = "";
        for (TextBlock block in recognisedText.blocks) {
          for (TextLine line in block.lines) {
            scannedText += line.text + "\n";
          }
        }
        textScanning = false;
      });

      getGrammaticalErrors(scannedText); // Call getGrammaticalErrors here
    } catch (e) {
      setState(() {
        textScanning = false;
        scannedText = "Error occurred while scanning";
      });
    }
  }

  Future<void> getGrammaticalErrors(String text) async {
    final url = Uri.parse('https://ginger4.p.rapidapi.com/correction');

    final response = await http.post(
      url,
      headers: {
        'content-type': 'text/plain',
        'Accept-Encoding': 'identity',
        'X-RapidAPI-Key': 'ae48859605msh84bae1d5704e7c6p127fc4jsnc918a9a4a4ae',
        'X-RapidAPI-Host': 'ginger4.p.rapidapi.com',
      },
      body: '"$text"',
    );

    if (response.statusCode == 200) {
      setState(() {
        scannedText = response.body;
      });
    } else {
      print('Error ${response.statusCode}: ${response.reasonPhrase}');
      print('Response body: ${response.body}');
      setState(() {
        // scannedText = "Error occurred during grammatical error check";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Text Recognition example"),
          backgroundColor: Color.fromARGB(255, 68, 220, 207),
        ),
        body: Container(
          decoration: const BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.cover, image: AssetImage('assets/image1.png'))),
          child: Center(
              child: SingleChildScrollView(
            child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (textScanning) const CircularProgressIndicator(),
                    if (!textScanning && imageFile == null)
                      Container(
                        width: 300,
                        height: 300,
                        color: Color.fromARGB(255, 111, 166, 173),
                      ),
                    if (imageFile != null) Image.file(File(imageFile!.path)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Color.fromARGB(255, 93, 128, 188),
                                backgroundColor: Colors.white,
                                shadowColor: Colors.grey[400],
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)),
                              ),
                              onPressed: () {
                                getImage(ImageSource.gallery);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 30,
                                    ),
                                    Text(
                                      "Gallery",
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  ],
                                ),
                              ),
                            )),
                        Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Color.fromARGB(255, 93, 128, 188),
                                backgroundColor: Colors.white,
                                shadowColor: Colors.grey[400],
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)),
                              ),
                              onPressed: () {
                                getImage(ImageSource.camera);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 30,
                                    ),
                                    Text(
                                      "Camera",
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    )
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      color: Colors.black,
                      child: Text(
                        scannedText,
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    )
                  ],
                )),
          )),
        ),
      ),
    );
  }
}
