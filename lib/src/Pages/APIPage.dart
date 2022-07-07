import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIPage extends StatefulWidget {
  const APIPage({Key? key}) : super(key: key);

  @override
  State createState() {
    return APIPageState();
  }
}

class APIPageState extends State<APIPage> {
  String title = "";
  List<String> usedIng = [];
  List<String> missIng = [];

  @override
  initState() {
    loadRecipe();
    super.initState();
  }

  Future<void> loadRecipe() async {
    final result = await FirebaseFirestore.instance
        .collection('Item')
        .where("userRef",
            isEqualTo: "${FirebaseAuth.instance.currentUser?.uid}")
        .get();

    final List<DocumentSnapshot> items = result.docs;

    final cntsSpecial = RegExp(r"[^A-Za-z0-9\s\'\/]");

    StringBuffer sb = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      String name = items[i]["Name"];

      if (cntsSpecial.hasMatch(name)) {
        String regex =
            r'[^\p{Alphabetic}\p{Mark}\p{Decimal_Number}\p{Connector_Punctuation}\p{Join_Control}\s]+';
        sb.write(name.replaceAll(RegExp(regex, unicode: true), "") + ",");
      } else {
        sb.write(name + ",");
      }
    }

    String postURL =
        "https://api.spoonacular.com/recipes/findByIngredients?ingredients=" +
            sb.toString() +
            "&number=2&limitLicense=true&ranking=1&ignorePantry=false" +
            "&apiKey=" +
            dotenv.env['spoonKey']!;

    Request request = Request("get", Uri.parse(postURL));

    var letsGo = await request.send();
    var response = await Response.fromStream(letsGo);
    var res = (jsonDecode(response.body) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    debugPrint("Points Left:" + response.headers['x-api-quota-left']!);

    List<String> tempUsed = [];
    List<String> tempMiss = [];
    for (int i = 0; i < res[0]['usedIngredients'].length; i++) {
      tempUsed.add(res[0]['usedIngredients'][i]['name']);
    }
    for (int i = 0; i < res[0]['missedIngredients'].length; i++) {
      tempMiss.add(res[0]['missedIngredients'][i]['name']);
    }

    setState(() {
      title = res[0]['title'];
      usedIng = tempUsed;
      missIng = tempMiss;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Posts"),
        ),
        body: Column(
          children: [
            Text(title),
            Text("Used: ${usedIng.toString()}"),
            Text("Missing: ${missIng.toString()}")
          ],
        ));
  }
}
