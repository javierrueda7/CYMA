import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:forms_app/services/firebase_services.dart';

class FormsPage extends StatefulWidget {
  final String idForm; // Nullable to differentiate between adding and editing
  final String formName;
  final String dates;
  final String uidUser;
  final String hours;
  FormsPage({super.key, required this.idForm, required this.formName, required this.dates, required this.uidUser, required this.hours});
  
  @override
  State<FormsPage> createState() => _FormsPageState();
}

class _FormsPageState extends State<FormsPage> {
  // Controllers
  final TextEditingController idTypeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController professionController = TextEditingController();
  final TextEditingController sedeController = TextEditingController();
  
  // Projects and activities
  List<Map<String, dynamic>> projects = [];
  List<Parametro> projectsList = [];
  List<Parametro> activitiesList = [];
  String expectedHours = '';
  int totalHours = 0;

  // Initialize controllers and data in initState
  @override
  void initState() {
    super.initState();
    retrieveData();
    initPro();
    initAct();
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    idTypeController.dispose();
    nameController.dispose();
    idController.dispose();
    roleController.dispose();
    positionController.dispose();
    professionController.dispose();
    sedeController.dispose();
    super.dispose();
  }

  Future<void> initPro() async {
    projectsList = await getParamwithId('Proyectos');
  }

  Future<void> initAct() async {
    activitiesList = await getParamwithId('Actividades');
  }

  Future<List<Parametro>> getSugProjects(String query) async {
    List<Parametro> savedProjects = await getParamwithId('Proyectos');
    List<Parametro> filteredProjects = savedProjects
        .where((project) => project.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return filteredProjects;
  }

  Future<List<Parametro>> getSugActivities(String query) async {
    List<Parametro> savedActivities = await getParamwithId('Actividades');
    List<Parametro> filteredActivities = savedActivities
        .where((activity) => activity.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return filteredActivities;
  }

  Future<List<Parametro>> getParamwithId(String param) async {
    List<Parametro> parametros = [];
    QuerySnapshot queryParametros = await FirebaseFirestore.instance.collection(param).where('status', isEqualTo: 'ACTIVO').get();
    for (var doc in queryParametros.docs) {
      parametros.add(Parametro(id: doc.id, name: doc['name']));
    }
    return parametros;
  }
  
  Future<void> retrieveData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(widget.uidUser)
          .get();

      if (snapshot.exists) {
        // Access data from snapshot
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          final profession = await fetchParameter('Profesiones', data['profession']);
          final position = await fetchParameter('Cargos', data['position']);
          setState(() {
            idTypeController.text = data['idType'] ?? '';
            idController.text = data['id'] ?? '';
            nameController.text = data['name'] ?? '';
            roleController.text = data['role'] ?? '';
            professionController.text = profession ?? '';
            positionController.text = position ?? '';
            sedeController.text = data['sede'] ?? '';
            expectedHours = widget.hours;
          });
        }
      }
    } catch (error) {
      print("Error retrieving data: $error");
    }
  }

  void updateTotalHours() {
    int newTotal = 0;
    for (var project in projects) {
      if (project['hours'] != null && project['hours'].isNotEmpty) {
        newTotal += int.parse(project['hours']);
      }
    }
    setState(() {
      totalHours = newTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('${widget.formName.toUpperCase()} - ${widget.dates}')),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(300, 50, 300, 50),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: buildTextField('TIPO DE DOCUMENTO', idTypeController, true)),            
                  SizedBox(width: 10),
                  Expanded(child: buildTextField('NÚMERO DE IDENTIFICACIÓN', idController, true)),
                  SizedBox(width: 10),
                  Expanded(child: buildTextField('SEDE', sedeController, true)),
                ],
              ),
              SizedBox(height: 10),
              buildTextField('NOMBRE', nameController, true),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: buildTextField('ROL', roleController, true)),
                  SizedBox(width: 10),            
                  Expanded(child: buildTextField('CARGO', positionController, true)),
                  SizedBox(width: 10),            
                  Expanded(child: buildTextField('PROFESIÓN', professionController, true)),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LISTA DE ACTIVIDADES',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'HORAS ESPERADAS: $expectedHours',
                        style: TextStyle(fontSize: 10,),
                      ),
                      Text(
                        'HORAS REGISTRADAS: $totalHours',
                        style: TextStyle(fontSize: 10,),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  return buildProjectItem(index);
                },
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    projects.add({});
                  });
                },
                child: Text('AGREGAR ACTIVIDAD'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Print all elements of the projects list
                  for (var project in projects) {
                    print(project);
                  }
                  // Implement submit functionality
                },
                child: Text('ENVIAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProjectItem(int index) {
    TextEditingController projectController = TextEditingController(text: projects[index]['projectName'] ?? '');
    TextEditingController activityController = TextEditingController(text: projects[index]['activityName'] ?? '');
    TextEditingController hoursController = TextEditingController(text: projects[index]['hours'] ?? '');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TypeAheadFormField<Parametro>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: projectController,
                  decoration: InputDecoration(
                    hintText: 'PROYECTO',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                ),
                suggestionsCallback: getSugProjects,
                onSuggestionSelected: (project) {
                  setState(() {                          
                    projects[index]['project'] = project.id;
                    projects[index]['projectName'] = project.name;
                    projectController.text = project.name;
                  });
                },
                autovalidateMode: AutovalidateMode.always,
                validator: (proyecto) {
                  if (proyecto!.isEmpty || !projectsList.any((project) => project.name == proyecto)) {
                    return 'SELECCIONE UN PROYECTO DE LA LISTA';
                  } else {
                    return null;
                  }
                },
                itemBuilder: (context, project) {
                  return ListTile(
                    title: Text(project.name),
                  );
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TypeAheadFormField<Parametro>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: activityController,
                  decoration: InputDecoration(
                    hintText: 'ACTIVIDAD',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                ),
                suggestionsCallback: getSugActivities,
                onSuggestionSelected: (activity) {
                  setState(() {                          
                    projects[index]['activity'] = activity.id;
                    projects[index]['activityName'] = activity.name;
                    activityController.text = activity.name;
                  });
                },
                autovalidateMode: AutovalidateMode.always,
                validator: (activity) {
                  if (activity!.isEmpty || !activitiesList.any((act) => act.name == activity)) {
                    return 'SELECCIONE UNA ACTIVIDAD DE LA LISTA';
                  } else {
                    return null;
                  }
                },
                itemBuilder: (context, activity) {
                  return ListTile(
                    title: Text(activity.name),
                  );
                },
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: hoursController,
                readOnly: false,
                keyboardType: TextInputType.number, // Set keyboard type to number
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly // Allow only digits
                ],
                decoration: InputDecoration(
                  labelText: 'HORAS DEDICADAS',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                onChanged: (value) {
                  setState(() {
                    projects[index]['hours'] = value;
                    updateTotalHours();
                  });                 
                },
              ),
            ),
            SizedBox(height: 10),
            IconButton(
              onPressed: () {
                setState(() {
                  projects.removeAt(index);
                  updateTotalHours();
                });
              },
              icon: Icon(Icons.delete_outline, color: Colors.red,),
            ),
          ],
        ),        
        Divider(),
      ],
    );
  }

  Widget buildTextField(String labelText, TextEditingController controller, bool readOnly) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    );
  }
}

class Parametro {
  final String id;
  final String name;

  Parametro({required this.id, required this.name});
}