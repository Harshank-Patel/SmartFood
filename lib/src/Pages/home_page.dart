import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:smartfood/src/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  List<String> titles = [];
  List<List<String>> usedIng = [];
  List<List<String>> missIng = [];
  List<String> imageURLs = [];
  List<int> recipeIDs = [];
  List<String> desc = [];
  List<String> urls = [];
  bool recipesLoaded = false;

  int _indexHi = 0;

  @override
  initState() {
    loadRecipe();

    super.initState();
  }

  Future<List<Map<String, dynamic>>?> makeRequest(String params,
      {ingSearch = false, recipeSearch = false, numberRecipes = 0}) async {
    String postURL = "";

    if (ingSearch) {
      postURL =
          "https://spoonacular-recipe-food-nutrition-v1.p.rapidapi.com/recipes/findByIngredients?ingredients=" +
              params +
              "&number=" +
              numberRecipes +
              "&limitLicense=true&ranking=1&ignorePantry=false";
    } else if (recipeSearch) {
      postURL =
          "https://spoonacular-recipe-food-nutrition-v1.p.rapidapi.com/recipes/informationBulk?ids=" +
              params;
    } else {
      return null;
    }

    Request request = Request("get", Uri.parse(postURL));

    request.headers.addAll({
      "X-RapidAPI-Host": dotenv.env['rapidHost']!,
      "X-RapidAPI-Key": dotenv.env['rapidKey']!
    });

    var letsGo = await request.send();
    var test = await letsGo.stream.bytesToString();
    var res = (jsonDecode(test) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    debugPrint(letsGo.headers['x-ratelimit-requests-remaining']);

    return res;
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

    String numberRecipes = "5";

    var res = await makeRequest(sb.toString(),
        ingSearch: true, numberRecipes: numberRecipes);

    sb.clear();

    List<String> tempTitles = [];
    List<List<String>> tempUsed = [];
    List<List<String>> tempMiss = [];
    List<String> tempURLs = [];
    List<int> tempIDs = [];

    if (res != null) {
      for (int i = 0; i < res.length; i++) {
        tempTitles.add(res[i]['title']);
        tempURLs.add(res[i]['image']);
        tempIDs.add(res[i]['id']);
      }
      for (int i = 0; i < res.length; i++) {
        List<String> recipeUsed = [];
        for (int j = 0; j < res[i]['usedIngredients'].length; j++) {
          recipeUsed.add(res[i]['usedIngredients'][j]['name']);
        }
        tempUsed.add(recipeUsed);
      }
      for (int i = 0; i < res.length; i++) {
        List<String> recipeMiss = [];
        for (int j = 0; j < res[i]['missedIngredients'].length; j++) {
          recipeMiss.add(res[i]['missedIngredients'][j]['name']);
        }
        tempMiss.add(recipeMiss);
      }
    }

    // Get Detailed list of Recipes
    for (int i = 0; i < tempIDs.length; i++) {
      sb.write(tempIDs[i].toString() + ",");
    }

    var res2 = await makeRequest(sb.toString(), recipeSearch: true);

    sb.clear();

    List<String> tempDesc = [];
    List<String> tempSourceURLs = [];

    if (res2 != null) {
      for (int i = 0; i < res2.length; i++) {
        String d = Bidi.stripHtmlIfNeeded(res2[i]['summary']);
        tempDesc.add(d);

        tempSourceURLs.add(res2[i]['sourceUrl']);
      }
    }

    setState(() {
      // Recipes by Ingredients
      titles = tempTitles;
      usedIng = tempUsed;
      missIng = tempMiss;
      imageURLs = tempURLs;
      recipeIDs = tempIDs;

      // Recipe summary and link
      desc = tempDesc;
      urls = tempSourceURLs;

      // Finish Loading
      recipesLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage'),
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Theme.of(context).backgroundColor, Colors.white])),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.only(right: 7),
                child: Text(
                  DateFormat('EEEE').format(DateTime.now()),
                  style: const TextStyle(fontSize: 50, color: Colors.black54),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.only(right: 7),
                child: Text(
                  DateFormat("yMMMMd").format(DateTime.now()),
                  style: const TextStyle(fontSize: 22, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 60),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.only(left: 7, bottom: 15),
                child: const Text(
                  "Recommended Recipes",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 20, color: Colors.black54),
                ),
              ),
            ),
            (recipesLoaded
                ? Flexible(
                    child: Center(
                    child: SizedBox(
                      height: 400, // card height
                      child: PageView.builder(
                        itemCount: titles.length,
                        controller: PageController(viewportFraction: 0.6),
                        onPageChanged: (int index) =>
                            setState(() => _indexHi = index),
                        itemBuilder: (_, i) {
                          return Transform.scale(
                              scale: i == _indexHi ? 1 : 0.8,
                              child: RecipeCard(
                                title: titles[i],
                                usedIng: usedIng[i],
                                missIng: missIng[i],
                                imageURL: imageURLs[i],
                                desc: desc[i],
                                url: urls[i],
                              ));
                        },
                      ),
                    ),
                  ))
                : const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
