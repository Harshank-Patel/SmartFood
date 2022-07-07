import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../widgets.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'dart:io' as io;

class CameraWidget extends StatefulWidget {
  const CameraWidget({Key? key}) : super(key: key);

  @override
  State createState() {
    return CameraWidgetState();
  }
}

class CameraWidgetState extends State {
  CollectionReference items = FirebaseFirestore.instance.collection('Item');
  XFile? imageFile;
  List<String> upcCodes = [];
  List<String> pluCodes = [];
  List<String> invItems = [];
  Map<int, String> pluMap = {};

  loadPLUCodes() async {
    var myData = await rootBundle.loadString("assets/plu.csv");
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(myData);

    for (int i = 0; i < csvTable.length; i++) {
      int code = csvTable[i][0];
      String name = csvTable[i][1];
      pluMap[code] = name;
    }
  }

  Future uploadImageToFirebase(BuildContext context) async {
    // Google OCR
    var filePath = imageFile!.path;
    final inputImage = InputImage.fromFilePath(filePath);
    final textDetector = GoogleMlKit.vision.textDetector();

    final RecognisedText recognisedText =
        await textDetector.processImage(inputImage);

    final alphanumeric = RegExp(r"(\d{1}\s*){12}\ F|(\d{1}\s*){12}KF");

    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        if (alphanumeric.hasMatch(line.text)) {
          parseInput(line.text);
        }
      }
    }

    textDetector.close();

    // Search codes and add to inventory
    await loadItems();

    // Send inventory to database
    await sendItems();
  }

  String? searchPLU(String pluCode) {
    int code = int.parse(pluCode);
    String? name = pluMap[code];
    return name;
  }

  void parseInput(String line) {
    int len = line.length;
    int digitCount = 0;
    StringBuffer sb = StringBuffer();

    final isPLU = RegExp(r"00000000|0000000");

    if (isPLU.hasMatch(line)) {
      // PLU Codes
      int idx = isPLU.firstMatch(line)!.end;

      for (int i = idx; i < len; i++) {
        if (isNumeric(line[i])) {
          sb.write(line[i]);
        }
      }

      pluCodes.add(sb.toString());
    } else {
      // UPC Codes
      for (int i = len - 1; i >= 0; i--) {
        if (isNumeric(line[i])) {
          sb.write(line[i]);
          digitCount++;
        }

        if (digitCount == 12) {
          // Add UPC code
          upcCodes.add(sb.toString().split('').reversed.join());
          break;
        }
      }
    }

    sb.clear();
  }

  bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  String calculateCheckDigit(String upc) {
    int sum = 0;

    var mults = [3, 1, 3, 1, 3, 1, 3, 1, 3, 1, 3, 0];
    for (int i = 0; i < upc.length; i++) {
      sum += (int.parse(upc[i]) * mults[i]);
    }

    sum %= 10;
    if (sum != 0) sum = 10 - sum;

    return sum.toString();
  }

  Future<void> loadItems() async {
    // Load PLU Codes
    for (int i = 0; i < pluCodes.length; i++) {
      String? name = searchPLU(pluCodes[i]);
      if (name != null) {
        // Add item to inventory
        invItems.add(name);
      } else {
        print("Invalid PLU Code");
      }
    }

    // Load UPC Codes
    for (int i = 0; i < upcCodes.length; i++) {
      String upc = upcCodes[i];
      if (upc[0] == '0') upc = upc.substring(1);
      upc += calculateCheckDigit(upc);

      String? name;
      if (i == upcCodes.length - 1) {
        name = await Future.delayed(const Duration(milliseconds: 250),
            () => makeRequest(upc, lastReq: true));
      } else {
        name = await Future.delayed(
            const Duration(milliseconds: 250), () => makeRequest(upc));
      }

      if (name != null) invItems.add(name);
    }

    // Clear UPC codes
    upcCodes.clear();
    pluCodes.clear();
  }

  Future<String?> makeRequest(String upc, {bool lastReq = false}) async {
    String spoonUrl =
        "https://spoonacular-recipe-food-nutrition-v1.p.rapidapi.com/food/products/upc/" +
            upc;

    Request request = Request("get", Uri.parse(spoonUrl));

    request.headers.addAll({
      "X-RapidAPI-Host": dotenv.env['rapidHost']!,
      "X-RapidAPI-Key": dotenv.env['rapidKey']!
    });

    var letsGo = await request.send();
    var response = await Response.fromStream(letsGo);
    final result = jsonDecode(response.body) as Map<String, dynamic>;

    if (lastReq) {
      debugPrint(
          "Points Left:" + response.headers['x-ratelimit-requests-remaining']!);
    }

    String? name = result['title'];
    if (name == null) {
      debugPrint("Could not find UPC code:" + upc);
    } else {
      name = result['title'];
      name = name!.split(',')[0];
    }

    return name;
  }

  Future<void> sendItems() async {
    // Combine same names??
    Map<String, int> itemNames = Map();

    setSearchParam(String name) {
      List<String> nameSearchList = [];
      String temp = "";
      for (int i = 0; i < name.length; i++) {
        temp = temp + name[i];
        nameSearchList.add(temp);
      }
      nameSearchList.add("");
      return nameSearchList;
    }

    for (String item in invItems) {
      if (itemNames.containsKey(item)) {
        itemNames[item] = itemNames[item]! + 1;
      } else {
        itemNames[item] = 1;
      }
    }

    for (String item in itemNames.keys) {
      // TODO remove hardcode expiration
      var now = DateTime.now();
      items.add({
        'Name': item,
        'Quantity': itemNames[item],
        'Expiration Date': DateTime(now.year, now.month, now.day + 14),
        'userRef': FirebaseAuth.instance.currentUser?.uid,
        'NameSearch': setSearchParam(item),
      }).catchError((error) => print("Failed to add item: $error"));
    }

    print("Inventory Updated");
    invItems.clear();

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _showChoiceDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              "Choose option",
              style: TextStyle(color: Colors.blue),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      _openGallery(context);
                    },
                    title: const Text("Gallery"),
                    leading: const Icon(
                      Icons.account_box,
                      color: Colors.blue,
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      _openCamera(context);
                    },
                    title: const Text("Camera"),
                    leading: const Icon(
                      Icons.camera,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget uploadImageButton(BuildContext context) {
    return Container(
      child: Stack(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
            margin: const EdgeInsets.only(
                top: 30, left: 20.0, right: 20.0, bottom: 20.0),
            child: MyElevatedButton(
              onPressed: () {
                uploadImageToFirebase(context);
              },
              child: const Text('Upload Receipt',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              borderRadius: BorderRadius.circular(20),
              width: 300,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Pick Image Camera"),
        ),
        body: Center(
          child: Container(
            child: SingleChildScrollView(
              // reverse: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    child: (imageFile == null)
                        ? const Text("Choose Image")
                        : Image.file(io.File(imageFile!.path)),
                  ),
                  Container(
                    child: (imageFile == null)
                        ? MaterialButton(
                            textColor: Colors.white,
                            color: Colors.pink,
                            onPressed: () {
                              _showChoiceDialog(context);
                            },
                            child: const Text("Select Image"),
                          )
                        : uploadImageButton(context),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _openGallery(BuildContext context) async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    setState(() {
      imageFile = pickedFile!;
    });

    await loadPLUCodes();

    Navigator.pop(context);
  }

  void _openCamera(BuildContext context) async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    setState(() {
      imageFile = pickedFile!;
    });

    await loadPLUCodes();

    Navigator.pop(context);
  }
}
