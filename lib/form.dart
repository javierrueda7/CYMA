// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:forms_app/services/firebase_services.dart';
import 'package:forms_app/widgets/forms_widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class FormsPage extends StatefulWidget {
  final String idForm; // Nullable to differentiate between adding and editing
  final String formName;
  final String dates;
  final String uidUser;
  final String hours;
  final String formState;
  final String answers;
  final DateTime date;
  final VoidCallback reloadList;
  FormsPage({super.key, required this.idForm, required this.formName, required this.dates, required this.uidUser, required this.hours, required this.formState, required this.answers, required this.date, required this.reloadList,});
  
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
  double totalHours = 0;
  bool enviarEncuesta = false;
  List<TextEditingController> projectControllers = [];
  List<TextEditingController> activityControllers = [];
  List<TextEditingController> hoursControllers = [];
  late final Future<void> dataFetch;
  bool isLoading = true; // Loading state


  // Initialize controllers and data in initState
  @override
  void initState() {
    super.initState();
    // Initialize lists and controllers here
    projects = [];
    projectControllers = [];
    activityControllers = [];
    hoursControllers = [];
    enviarEncuesta = widget.formState == 'ENVIADA' ?  true : false;
    _formKey = GlobalKey<FormState>();
    
    dataFetch = retrieveDataAndInit().whenComplete(() {
      if (widget.formState != 'ABIERTA' && widget.answers != 'NULL' && widget.answers.isNotEmpty) {
        projects = loadAnswers(widget.answers);
        print(1);
        print(projects);
        initializeControllers(projects);   
        updateTotalHours();
      }
    });    
    updateTotalHours();
    setState(() {
      isLoading = false; // Data is no longer loading
    });
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
    // Dispose all controllers
    for (var controller in projectControllers) {
      controller.dispose();
    }
    for (var controller in activityControllers) {
      controller.dispose();
    }
    for (var controller in hoursControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _reloadList() async {    
    await initPro().whenComplete(() async => await initAct()).whenComplete((() => setState(() {
      
    })));
  }

  Future<void> retrieveDataAndInit() async {
    await retrieveData().whenComplete(() async {      
      await initPro();
    }).whenComplete(() async {
      await initAct();
    });
    
  }

  Future<void> initPro() async {
    projectsList = await getParamwithId('Proyectos');
    projectsList.sort((a, b) => a.name.trim().compareTo(b.name.trim()));
  }

  Future<void> initAct() async {
    activitiesList = await getParamwithId('Actividades');
  }

  Future<List<Parametro>> getSugProjects(String query) async {
    List<Parametro> savedProjects = await getParamwithId('Proyectos');
    List<Parametro> filteredProjects = savedProjects
        .where((project) => project.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    filteredProjects.sort((a, b) => a.name.trim().compareTo(b.name.trim()));
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
    QuerySnapshot queryParametros;
    if(widget.formState == 'ENVIADA'){
      queryParametros = await FirebaseFirestore.instance.collection(param).get();
    } else {
      queryParametros = await FirebaseFirestore.instance.collection(param).where('status', isNotEqualTo: 'INACTIVO').get();
    }
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

  void addProject() {
    setState(() {
      final newProject = {
        'projectName': '',
        'activityName': '',
        'hours': '0'
      };
      projects.add(newProject);
      final projectController = TextEditingController();
      final activityController = TextEditingController();
      final hoursController = TextEditingController();
      projectControllers.add(projectController);
      activityControllers.add(activityController);
      hoursControllers.add(hoursController);
      // Add listeners to update the projects list
      projectController.addListener(() {
        newProject['projectName'] = projectController.text;
      });
      activityController.addListener(() {
        newProject['activityName'] = activityController.text;
      });
      hoursController.addListener(() {
        newProject['hours'] = hoursController.text;
        updateTotalHours();
      });
    });
  }


  void removeProject(int index) {
    setState(() {
      projects.removeAt(index);
      projectControllers[index].dispose();
      activityControllers[index].dispose();
      hoursControllers[index].dispose();
      projectControllers.removeAt(index);
      activityControllers.removeAt(index);
      hoursControllers.removeAt(index);
      updateTotalHours();
    });
  }

  void updateTotalHours() {
    double newTotal = 0;
    for (var project in projects) {
      var temp = project['hours'];
      if (temp != null && temp.toString().isNotEmpty) {
        newTotal += double.parse(temp.toString());
      }
    }
    setState(() {
      totalHours = double.parse(newTotal.toStringAsFixed(1));
    });
  }


  bool pressed = false;

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('${widget.formName.toUpperCase()} - ${widget.dates}')),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(350, 50, 350, 50),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: FutureBuilder(
                  future: dataFetch,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      return Column(
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
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [                                                
                                  Checkbox(
                                    value: enviarEncuesta,
                                    onChanged: widget.formState != 'ENVIADA' ? (bool? value) {
                                      setState(() {
                                        enviarEncuesta = value ?? false;
                                      });
                                    } : null,
                                  ),
                                  Text('ENVIAR ENCUESTA'),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'HORAS ESPERADAS: $expectedHours',
                                  style: TextStyle(fontSize: 14,),
                                ),
                                Text(
                                  'HORAS REGISTRADAS: $totalHours',
                                  style: TextStyle(fontSize: 14,),
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
                          onPressed: isLoading || widget.formState == 'ENVIADA' ? null : addProject,
                          child: Text('AGREGAR ELEMENTO'),
                        ),
                        SizedBox(height: 20),
                        Visibility(
                          visible: widget.formState != 'ENVIADA',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ElevatedButton(onPressed: (){showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AddParam(param: 'Proyectos', reloadList: _reloadList);
                                    },
                                  );},
                                  child: Text('AGREGAR NUEVO PROYECTO')
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton(onPressed: (){showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AddParam(param: 'Actividades', reloadList: _reloadList);
                                    },
                                  );},
                                  child: Text('AGREGAR NUEVA ACTIVIDAD')
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: widget.formState == 'ENVIADA' || pressed ? null : () async {
                            String currentState = await getFormState(widget.idForm, widget.uidUser);
                            if (currentState != 'ENVIADA') {
                              
                              bool toReview = false;
                              bool confirmed = true; // Default to true if no confirmation is required

                              // Only show the confirmation dialog if enviarEncuesta is true
                              if (enviarEncuesta) {
                                confirmed = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('¿Está seguro de que desea enviar la encuesta?'),
                                      content: Text('Esta acción no es reversible.', style: TextStyle(fontSize: 18),),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false); // User cancels
                                          },
                                          child: Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true); // User confirms
                                          },
                                          child: Text('Confirmar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }

                              if (!confirmed) {
                                // If the user cancels, stop the process
                                setState(() {
                                  isLoading = false;
                                  pressed = false;
                                });
                                return;
                              }

                              setState(() {
                                pressed = true;
                                isLoading = true; // Data is now loading
                              });

                              // Continue with the rest of your logic to update projects and send the survey...
                              setState(() {
                                for (int i = 0; i < projects.length; i++) {
                                  projects[i]['projectName'] = projectControllers[i].text;
                                  projects[i]['activityName'] = activityControllers[i].text;
                                  projects[i]['hours'] = hoursControllers[i].text;
                                }
                              });

                              if (projects.isEmpty && enviarEncuesta) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Por favor, agregue al menos una actividad.'),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                                setState(() {
                                  isLoading = false;
                                  pressed = false;
                                });
                                return;
                              }

                              for (var controller in activityControllers) {
                                if (controller.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Por favor, complete todos los campos de actividades.'),
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                  setState(() {
                                    isLoading = false;
                                    pressed = false;
                                  });
                                  return; // Prevent form submission if any activityController is empty
                                }
                              }

                              for (var controller in projectControllers) {
                                if (controller.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Por favor, complete todos los campos de proyectos.'),
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                  setState(() {
                                    isLoading = false;
                                    pressed = false;
                                  });
                                  return; // Prevent form submission if any projectController is empty
                                }
                              }

                              // Check if any hoursController is empty
                              for (var controller in hoursControllers) {
                                if (controller.text.isEmpty || controller.text == '0') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Por favor, complete todos los campos de horas.'),
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                  setState(() {
                                    isLoading = false;
                                    pressed = false;
                                  });
                                  return; // Prevent form submission if any hoursController is empty
                                }
                              }

                              // Then, handle new projects and activities
                              for (var project in projects) {
                                if (!projectsList.any((p) => p.name == project['projectName'])) {
                                  // Check if project was already created in this session
                                  toReview = true;
                                } else {
                                  project['project'] = projectsList.firstWhere((p) => p.name == project['projectName']).id;
                                }

                                if (!activitiesList.any((a) => a.name == project['activityName'])) {
                                  // Check if activity was already created in this session
                                  toReview = true;
                                } else {
                                  project['activity'] = activitiesList.firstWhere((a) => a.name == project['activityName']).id;
                                }
                              }

                              if (!toReview) {
                                List<String> projectStrings = [];

                                for (var project in projects) {
                                  projectStrings.add("?idencuesta=${widget.idForm}&idusuario=${widget.uidUser}&proyecto=${project['project']}&actividad=${project['activity']}&horas=${project['hours']}&fecha=${DateTime.now()}");
                                }

                                String resultString = projectStrings.join(';');
                                
                                bool tempEnv = enviarEncuesta;
                                await FirebaseFirestore.instance
                                .collection('Encuestas').doc(widget.idForm)
                                .collection('Usuarios').doc(widget.uidUser)
                                .update({
                                  'answer': resultString,
                                  'status': tempEnv ? 'ENVIADA' : 'GUARDADA',
                                  'date': DateTime.now(),
                                  'idencuesta': widget.idForm,
                                });
                                if (tempEnv) {
                                  const String scriptURL = 'https://script.google.com/macros/s/AKfycbwl1b-qt61HCxZG2QtLYNsqvmAgVQ6NRUmEGbV0SQQaL4Hl6Yh3pwF2WpNkk-EJrAlq/exec';
                                  for (var project in projects) {
                                    String queryString = "?idencuesta=${widget.idForm}&idusuario=${widget.uidUser}&proyecto=${project['project']}&actividad=${project['activity']}&horas=${project['hours']}&fecha=${DateTime.now()}";
                                    var finalURI = Uri.parse(scriptURL + queryString);
                                    var response = await http.get(finalURI);
                                    if (response.statusCode == 200) {
                                      var bodyR = convert.jsonDecode(response.body);
                                      print(bodyR);
                                    }
                                  }
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tempEnv ? 'Encuesta enviada exitosamente.' : 'Encuesta guardada exitosamente.'),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                                widget.reloadList();
                                setState(() {
                                  isLoading = false; // Data is no longer loading
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Por favor, cree los proyectos o actividades faltantes.'),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                                setState(() {
                                  isLoading = false;
                                  pressed = false;
                                });
                                return;
                              }
                              widget.reloadList();
                              setState(() {
                                isLoading = false; // Data is no longer loading
                              });
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Esta encuesta ya fue enviada.'),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              setState(() {});
                            }
                          },
                          child: Text(enviarEncuesta ? 'ENVIAR ENCUESTA' : 'GUARDAR ENCUESTA'),
                        ),

          
                      ],
                    );
                  }
                }),
              ),
            ),
          ),
          if (isLoading)
            Center(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        "ENVIANDO ENCUESTA, POR FAVOR NO CIERRE ESTA VENTANA",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  late final _formKey;
  bool saving = false;
  
  List<Map<String, String>> loadAnswers(String encodedString) {
    List<Map<String, String>> parsedList = [];
    List<String> items = encodedString.split(';');
    for (String item in items) {
      if (item.isEmpty) continue;
      Map<String, String> itemMap = {};
      List<String> keyValuePairs = item.split('&');
      String proyectoValue = '';
      String activityValue = '';
      for (String keyValuePair in keyValuePairs) {
        List<String> keyValue = keyValuePair.split('=');
        if (keyValue.length == 2) {
          String key = keyValue[0];
          String value = Uri.decodeComponent(keyValue[1]);
          if (key.startsWith('?')) {
            key = key.substring(1);
          }
          switch (key) {
            case 'proyecto':
              key = 'project';
              proyectoValue = value;
              break;
            case 'actividad':
              key = 'activity';
              activityValue = value;
              break;
            case 'horas':
              key = 'hours';
              break;
          }
          itemMap[key] = value;
        }
      }
      itemMap['projectName'] = getProjectNameById(proyectoValue);
      itemMap['activityName'] = getActivityNameById(activityValue);
      parsedList.add(itemMap);
    }
    return parsedList;
  }

  void initializeControllers(List<Map<String, dynamic>> answers){
    for (int i = 0; i < answers.length; i++) {
      var answer = answers[i];
      if (answer.containsKey('project') && answer.containsKey('activity')) {
        String projectId = answer['project'] ?? '';
        String activityId = answer['activity'] ?? '';
        String projectName = getProjectNameById(projectId);
        String activityName = getActivityNameById(activityId);
        while (projectControllers.length <= i) {
          projectControllers.add(TextEditingController());
        }
        while (activityControllers.length <= i) {
          activityControllers.add(TextEditingController());
        }
        while (hoursControllers.length <= i) {
          hoursControllers.add(TextEditingController());
        }
        projectControllers[i].text = projectName;
        activityControllers[i].text = activityName;
        hoursControllers[i].text = answer['hours'] ?? '';
      }
    }
  }

  Widget buildProjectItem(int index) {
    TextEditingController projectController = projectControllers[index];
    TextEditingController activityController = activityControllers[index];
    TextEditingController hoursController = hoursControllers[index];
    projectController.addListener(() {
      final text = projectController.text.toUpperCase();
      if (projectController.text != text) {
        projectController.value = projectController.value.copyWith(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
    activityController.addListener(() {
      final text = activityController.text.toUpperCase();
      if (activityController.text != text) {
        activityController.value = activityController.value.copyWith(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TypeAheadFormField<Parametro>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: projectController,

                  enabled: widget.formState != 'ENVIADA', // Más claro
                  decoration: InputDecoration(
                    labelText: 'PROYECTO',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  style: TextStyle(
                    color: widget.formState == 'ENVIADA' ? Colors.black : null, // Cambia el color del texto si está deshabilitado
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
                  if (proyecto!.isEmpty) {
                    return 'SELECCIONE UN PROYECTO DE LA LISTA';
                  } else if (!projectsList.any((project) => project.name == proyecto)) {
                    return 'DEBE CREAR UN NUEVO PROYECTO';
                  } else {
                    return null;
                  }
                },
                itemBuilder: (context, project) {
                  return ListTile(
                    title: Text(project.name),
                  );
                },
                onSaved: (proyecto) async {
                  if (proyecto != null && !projectsList.any((project) => project.name == proyecto)) {
                    await saveParameter('Proyectos', proyecto, 'PENDIENTE');
                    projectsList.add(Parametro(id: DateTime.now().toString(), name: proyecto)); // Temporarily add the new project
                  }
                },
                noItemsFoundBuilder: (context) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TypeAheadFormField<Parametro>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: activityController,
                  enabled: widget.formState != 'ENVIADA', // Más claro
                  decoration: InputDecoration(
                    labelText: 'ACTIVIDAD',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  style: TextStyle(
                    color: widget.formState == 'ENVIADA' ? Colors.black : null, // Cambia el color del texto si está deshabilitado
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
                  if (activity!.isEmpty) {
                    return 'SELECCIONE UNA ACTIVIDAD DE LA LISTA';
                  } else if (!activitiesList.any((act) => act.name == activity)) {
                    return 'DEBE CREAR UNA NUEVA ACTIVIDAD';
                  } else {
                    return null;
                  }
                },
                itemBuilder: (context, activity) {
                  return ListTile(
                    title: Text(activity.name),
                  );
                },
                onSaved: (activity) async {
                  // Save the ocupacion to Firebase if it's a new value
                  if (!activitiesList.any((act) => act.name == activity)) {
                    saveParameter('Actividades', activity!, 'PENDIENTE');
                  }
                },
                noItemsFoundBuilder: (context) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: hoursController,
                enabled: widget.formState != 'ENVIADA' ? true : false,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'HORAS DEDICADAS',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                style: TextStyle(
                  color: widget.formState == 'ENVIADA' ? Colors.black : null, // Cambia el color del texto si está deshabilitado
                ),
                onChanged: (value) {
                  double? newValue = double.tryParse(value);
                  setState(() {
                    projects[index]['hours'] = newValue?.toString(); // Store as String to avoid type issues
                    updateTotalHours();
                  });
                  // Preserve cursor position
                  hoursController.value = hoursController.value.copyWith(
                    text: value,
                    selection: TextSelection.collapsed(offset: value.length),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            IconButton(
              onPressed: widget.formState == 'ENVIADA' ? null : () {
                removeProject(index);
              },
              icon: Icon(Icons.delete_outline, color: widget.formState == 'ENVIADA' ? Colors.grey : Colors.red),
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

  String getProjectNameById(String id) {
    print(id);
    print(projectsList);
    var project = projectsList.firstWhere((project) => project.id == id, orElse: () => Parametro(id: '', name: ''));
    return project.name;
  }

  String getActivityNameById(String id) {
    print(id);
    print(activitiesList);
    var activity = activitiesList.firstWhere((activity) => activity.id == id, orElse: () => Parametro(id: '', name: ''));
    return activity.name;
  }
}

class Parametro {
  final String id;
  final String name;
  Parametro({required this.id, required this.name});
}

class AddParam extends StatefulWidget {
  final String param;
  final VoidCallback reloadList;

  AddParam({required this.param, required this.reloadList});

  @override
  // ignore: library_private_types_in_public_api
  _AddParamState createState() => _AddParamState();
}

class _AddParamState extends State<AddParam> {
  late String id;
  TextEditingController nameController = TextEditingController();
  String selectedEstado = 'PENDIENTE';
  bool isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: Center(child: Text('AGREGAR ${widget.param.toUpperCase()}')),
      content: SizedBox(
        height: 200,
        child: Padding(
          padding: EdgeInsets.fromLTRB(300, 30, 300, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildTextField('NOMBRE', nameController, false),
            ],
          ),
        ),
      ),
      actions: [
        isLoading
            ? Center(child: CircularProgressIndicator()) // Show loading indicator
            : TextButton(
                onPressed: () {
                  if (isLoading) return; // Prevent further actions if loading
                  setState(() {
                    isLoading = true; // Set loading state to true
                  });
                  _saveParameter(context);
                },
                child: Text('AGREGAR'),
              ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('CANCELAR'),
        ),
      ],
    );
  }

  void _saveParameter(BuildContext context) async {
    String nombre = nameController.text;
    String estado = selectedEstado;
    String param = widget.param;
    try {
      await saveParameter(param, nombre, estado);
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parámetro guardado exitosamente.'),
          duration: Duration(seconds: 4),
        ),
      );
      // Clear the name field after saving
      nameController.clear();
      // Trigger a refresh of the list by calling setState
      widget.reloadList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el parámetro: $e'),
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      Navigator.of(context).pop();
      setState(() {
        isLoading = false; // Reset loading state
      });
    }
  }  
}
