import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterfire_ui/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:smartfood/src/Pages/new_item_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State createState() {
    return InventoryPageState();
  }
}

class InventoryPageState extends State<InventoryPage> {
  @override
  initState() {
    super.initState();
  }

  TextEditingController searchCtl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final itemQuery = FirebaseFirestore.instance.collection('Item').where(
        "userRef",
        isEqualTo: "${FirebaseAuth.instance.currentUser?.uid}");

    return Scaffold(
        backgroundColor: const Color.fromRGBO(255, 195, 0, 0.6),
        appBar: AppBar(
          title: const Text('Inventory'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add an item to your inventory',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewItemPage()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
              child: Container(
                child: TextField(
                  controller: searchCtl,
                  onChanged: (text) => setState(() {}),
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    hintText: 'Search',
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            ),
            Flexible(
                child: FirestoreListView<Map<String, dynamic>>(
              shrinkWrap: true,
              query:
                  itemQuery.where("NameSearch", arrayContains: searchCtl.text),
              itemBuilder: (context, snapshot) {
                Map<String, dynamic> item = snapshot.data();
                // print(itemQuery.parameters);

                int daysUntilExpire = item['Expiration Date']
                    .toDate()
                    .difference(DateTime.now())
                    .inDays;
                String expireText = "Expires in ${daysUntilExpire} days";

                if (daysUntilExpire < 0) {
                  if (daysUntilExpire == -1) {
                    expireText = "${-daysUntilExpire} day past expiration";
                  } else {
                    expireText = "${-daysUntilExpire} days past expiration";
                  }
                } else if (daysUntilExpire == 0) {
                  expireText = "Expiring today";
                } else if (daysUntilExpire == 1) {
                  expireText = "Expires tomorrow";
                }

                return Card(
                  child: ExpansionTile(
                    title: Text(
                      "${item['Name']}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(expireText,
                        style: TextStyle(
                            color: daysUntilExpire <= 3
                                ? Colors.red
                                : Colors.black)),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Text(
                              "Quantity: ${item['Quantity']}",
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                            ElevatedButton(
                                onPressed: () {
                                  snapshot.reference.update(
                                      {"Quantity": FieldValue.increment(-1)});
                                },
                                child: const Text("-")),
                            ElevatedButton(
                                onPressed: () {
                                  snapshot.reference.update(
                                      {"Quantity": FieldValue.increment(1)});
                                },
                                child: const Text("+")),
                          ],
                        ),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            snapshot.reference.delete();
                          },
                          child: const Text("Delete")),
                    ],
                  ),
                );
              },
            )),
          ],
        ));
  }
}
