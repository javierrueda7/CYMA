import 'package:flutter/material.dart';
import 'package:forms_app/form.dart';
import 'package:forms_app/services/firebase_services.dart';

class ListUserForms extends StatefulWidget {

  ListUserForms({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ListUserFormsState createState() => _ListUserFormsState();
}

class _ListUserFormsState extends State<ListUserForms> {
  
  String uid= 'MHQVnaRX42P8wcRYL4jx7d5cf2S2';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('ENCUESTAS')),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(300, 50, 300, 50),
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
                future: getEncuestasUser(uid),
                builder: ((context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data?[index];
                        return ListTile(
                          leading: Text(item?['id']),
                          title: Text(item?['data']['name']),
                          subtitle: Text(item?['data']['startDate'] + ' - ' + item?['data']['endDate']),
                          trailing: Text(item?['data']['status']),
                          onTap: () {
                            if(item?['data']['status'] == 'ACTIVA'){
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => FormsPage(
                                  idForm: item?['id'], // Accessing the document ID
                                  formName: item?['data']['name'],
                                  dates: item?['data']['startDate'] + ' - ' + item?['data']['endDate'],
                                  uidUser: uid,
                                  hours: ((int.parse(item?['data']['days']))*9).toString()
                                )), // Navigate to the NewUserPage
                              );
                            }
                          },
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
}

