// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:forms_app/form.dart';
import 'package:forms_app/services/firebase_services.dart';
import 'package:intl/intl.dart';

class ListUserForms extends StatefulWidget {
  final String uid;

  ListUserForms({super.key, required this.uid});

  @override
  // ignore: library_private_types_in_public_api
  _ListUserFormsState createState() => _ListUserFormsState();
}

class _ListUserFormsState extends State<ListUserForms> {
  late String uid;
  // ignore: unused_field
  late Future<List<dynamic>> _futureForms;

  @override
  void initState() {
    super.initState();
    uid = widget.uid;
    _futureForms = getEncuestasUser(uid); // cargamos por primera vez
  }

  bool isLoading = false;

  void _reloadList() {
    setState(() {
      // forzamos a FutureBuilder a usar un Future NUEVO
      _futureForms = getEncuestasUser(uid);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('ENCUESTAS')),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(350, 50, 350, 50),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ENCUESTAS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ESTADO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ), // Add spacing between header and FutureBuilder
            ),
            SizedBox(height: 10),
            Expanded(
              child: FutureBuilder(
                future: _futureForms,
                builder: ((context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data?[index];
                        return ListTile(
                          leading: Text(item?['id'], style: TextStyle(fontSize: 16),),
                          title: Text(item?['data']['name']),
                          subtitle: Text(item?['data']['startDate'] + ' - ' + item?['data']['endDate']),
                          trailing: SizedBox(
                            width: 150,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                item?['user']['status'] != 'ABIERTA' ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item?['user']['status'], style: TextStyle(fontSize: 14),),
                                    Text(DateFormat('dd-MM-yyyy HH:mm').format(item?['user']['date'].toDate()), style: TextStyle(fontSize: 12),)
                                  ],
                                ) : Text(item?['data']['status'], style: TextStyle(fontSize: 14),),
                                SizedBox(width: 8,),
                                IconButton(
                                  onPressed: () async {
                                    String? status = await getStatus(item?['id'], uid);
                                    print(status);
                                    if (status != item?['user']['status']) {
                                      _reloadList();
                                    }

                                    if (item?['data']['status'] == 'ACTIVA') {
                                      // ACTIVA: se puede editar / responder
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FormsPage(
                                            idForm: item?['id'], // Accessing the document ID
                                            formName: item?['data']['name'],
                                            dates: item?['data']['startDate'] +
                                                ' - ' +
                                                item?['data']['endDate'],
                                            uidUser: uid,
                                            hours: max(
                                              (int.parse(item?['data']['days']) * 9) - 1,
                                              0,
                                            ).toString(),
                                            formState: item?['user']['status'],
                                            answers: item?['user']['status'] == 'ABIERTA'
                                                ? 'NULL'
                                                : item?['user']['answer'],
                                            date: item?['user']['status'] == 'ABIERTA'
                                                ? DateTime.now()
                                                : (item?['user']['date'] as Timestamp).toDate(),
                                            reloadList: _reloadList,
                                          ),
                                        ),
                                      );
                                    } else {
                                      // NO ACTIVA: solo visualizar, y mostrar mensaje
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FormsPage(
                                            idForm: item?['id'], // Accessing the document ID
                                            formName: item?['data']['name'],
                                            dates: item?['data']['startDate'] +
                                                ' - ' +
                                                item?['data']['endDate'],
                                            uidUser: uid,
                                            hours: max(
                                              (int.parse(item?['data']['days']) * 9) - 1,
                                              0,
                                            ).toString(),
                                            formState: 'ENVIADA',
                                            answers: item?['user']['status'] == 'ABIERTA'
                                                ? 'NULL'
                                                : item?['user']['answer'],
                                            date: item?['user']['status'] == 'ABIERTA'
                                                ? DateTime.now()
                                                : (item?['user']['date'] as Timestamp).toDate(),
                                            reloadList: _reloadList,
                                          ),
                                        ),
                                      );

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('La encuesta ya ha sido cerrada.'),
                                          duration: Duration(seconds: 4),
                                        ),
                                      );
                                    }

                                    // 🔁 Al volver de FormsPage, volvemos a consultar Firestore
                                    _reloadList();
                                  },
                                  icon: item?['user']['status'] == 'ENVIADA'
                                      ? const Icon(Icons.visibility, color: Colors.blueAccent)
                                      : const Icon(Icons.edit, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> getStatus(String itemId, String uid) async {
    try {
      // Fetch the document snapshot from Firebase
      var documentSnapshot = await FirebaseFirestore.instance
          .collection('Encuestas')
          .doc(itemId)
          .collection('Usuarios')
          .doc(uid)
          .get();

      if (documentSnapshot.exists) {
        // Extract the data and retrieve the 'status'
        var data = documentSnapshot.data();
        return data?['status'];
      } else {
        // Handle the case where the document does not exist
        return null; // or handle as appropriate
      }
    } catch (e) {
      // Handle any errors that occur during data retrieval
      print('Error retrieving status: $e');
      return null; // or handle as appropriate
    }
  }

}


