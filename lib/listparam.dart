// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:forms_app/services/firebase_services.dart';
import 'package:forms_app/widgets/forms_widgets.dart';

class ListParameterScreen extends StatefulWidget {
  final String param;

  ListParameterScreen({super.key, required this.param});

  @override
  // ignore: library_private_types_in_public_api
  _ListParameterScreenState createState() => _ListParameterScreenState();
}

class _ListParameterScreenState extends State<ListParameterScreen> {

  void _reloadList() {
    setState(() {}); // Empty setState just to trigger rebuild
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('ADMINISTRACIÓN DE ${widget.param.toUpperCase()}')),
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
                    widget.param.toUpperCase(),
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
                future: getParametro(widget.param),
                builder: ((context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data?[index];
                        return ListTile(
                          leading: SizedBox(child: item?['data']['status'] == 'PENDIENTE' ? Icon(Icons.circle, color: Colors.red,) : SizedBox()),
                          title: Text(item?['data']['name']),
                          trailing: Text(item?['data']['status'], style: TextStyle(fontSize: 14),),
                          onTap: () {
                            // Open edit dialog or perform edit action here
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AddEditParam(
                                  param: widget.param,
                                  reloadList: _reloadList,
                                  id: item?['id'], // Accessing the document ID
                                  name: item?['data']['name'],
                                  status: item?['data']['status'],
                                );
                              },
                            );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddEditParam(param: widget.param, reloadList: _reloadList);
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}


// ignore: must_be_immutable
class AddEditParam extends StatefulWidget {
  final String param;
  final String? name; // Nullable to differentiate between adding and editing
  final String? status; // Nullable to differentiate between adding and editing
  final String? id;
  final VoidCallback reloadList;

  AddEditParam({required this.param, this.id, this.name, this.status, required this.reloadList});

  @override
  // ignore: library_private_types_in_public_api
  _AddEditParamState createState() => _AddEditParamState();
}

class _AddEditParamState extends State<AddEditParam> {
  late String id;
  late TextEditingController nameController;
  late String selectedEstado;
  late bool isEditing; // Indicates whether it's an edit operation
  bool isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    id = widget.id ?? '';
    nameController = TextEditingController(text: widget.name ?? '');
    if(widget.status == 'PENDIENTE'){
      selectedEstado = 'ACTIVO';
    } else {
      selectedEstado = widget.status ?? 'ACTIVO';
    }
    isEditing = widget.id != null; // If name and status are not null, it's an edit operation
  }

  @override
  Widget build(BuildContext context) {
    final List<String> estados = ['ACTIVO', 'INACTIVO'];

    return AlertDialog(
      title: Center(child: Text(isEditing ? 'EDITAR ${widget.param.toUpperCase()}' : 'AGREGAR ${widget.param.toUpperCase()}')),
      content: SizedBox(
        height: 200,
        child: Padding(
          padding: EdgeInsets.fromLTRB(300, 30, 300, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildTextField('NOMBRE', nameController, false),
              SizedBox(height: 20),
              buildDropdownField('ESTADO', estados, (value) {
                setState(() {
                  selectedEstado = value ?? 'ACTIVO';
                });
              }, initialValue: selectedEstado, allowChange: true),
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
                  if (isEditing) {
                    _updateParameter(context);
                  } else {
                    _saveParameter(context);
                  }
                },
                child: Text(isEditing ? 'GUARDAR' : 'AGREGAR'),
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

  void _updateParameter(BuildContext context) async {
    String id = widget.id ?? '';
    String nombre = nameController.text;
    String estado = selectedEstado;
    String param = widget.param;

    try {
      updateParameter(id, param, nombre, estado);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parámetro actualizado exitosamente.'),
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
          content: Text('Error al actualizar el parámetro: $e'),
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

