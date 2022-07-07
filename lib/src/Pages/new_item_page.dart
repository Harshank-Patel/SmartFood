import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'camera_page.dart';

class NewItemPage extends StatelessWidget {
  NewItemPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Add an Item"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
              reverse: true,
              child: Column(
                children: [
                  const AddItemForm(),
                  Row(children: const <Widget>[
                    Expanded(child: Divider()),
                    Text("OR"),
                    Expanded(child: Divider()),
                  ]),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 16.0),
                        margin: const EdgeInsets.only(
                            top: 30, left: 20.0, right: 20.0, bottom: 20.0),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.green],
                            ),
                            borderRadius: BorderRadius.circular(30.0)),
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CameraWidget()),
                          ),
                          child: const Text(
                            "Scan Reciept",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
        ));
  }
}

class AddItemForm extends StatefulWidget {
  const AddItemForm({Key? key}) : super(key: key);

  @override
  AddItemFormState createState() {
    return AddItemFormState();
  }
}

class AddItemFormState extends State<AddItemForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameCtl = TextEditingController();
  TextEditingController quantityCtl = TextEditingController();
  TextEditingController dateCtl = TextEditingController();
  CollectionReference items = FirebaseFirestore.instance.collection('Item');
  DateTime formDate = DateTime.now();

  Future<void> addItem() {
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

    return items
        .add({
          'Name': nameCtl.text,
          'Quantity': quantityCtl.text,
          'Expiration Date': formDate,
          'userRef': FirebaseAuth.instance.currentUser?.uid,
          'NameSearch': setSearchParam(nameCtl.text),
        })
        .then((value) => Navigator.pop(context))
        .catchError((error) => print("Failed to add item: $error"));
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'What is the item called?',
              labelText: 'Name *',
            ),
            controller: nameCtl,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          TextFormField(
            // The validator receives the text that the user has entered.
            decoration: const InputDecoration(
              hintText: 'How many do you have?',
              labelText: 'Quantity *',
            ),
            controller: quantityCtl,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {}
              return null;
            },
          ),
          TextFormField(
            controller: dateCtl,
            decoration: InputDecoration(
              labelText: "Expiration Date",
              hintText: "When will this item expire?",
            ),
            onTap: () async {
              DateTime date = DateTime(1900);
              FocusScope.of(context).requestFocus(new FocusNode());

              date = (await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100)))!;

              formDate = date;
              dateCtl.text = date.toIso8601String();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState!.validate()) {
                  // If the form is valid, display a snackbar. In the real world,
                  // you'd often call a server or save the information in a database.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adding Item')),
                  );
                  addItem();
                }
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
