// ignore_for_file: avoid_web_libraries_in_flutter, library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:forms_app/counter.dart';
import 'package:forms_app/listforms.dart';
import 'package:forms_app/listparam.dart';
import 'package:forms_app/listusers.dart';
import 'package:forms_app/userforms.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:js' as js;


class MainMenu extends StatefulWidget {
  final String? role;
  final String? uid;
  MainMenu({super.key, required this.role, required this.uid});
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  String role = 'ANON';
  String uid = '';

  @override
  void initState() {
    super.initState();
    role = widget.role ?? role;
    uid = widget.uid ?? uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('CYMA - ENCUESTAS MOP')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
              visible: role != 'ADMINISTRADOR',
              child: Column(
                children: [
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListUserForms(uid: uid)),
                      );
                    },
                    child: Text('RESPONDER ENCUESTA'),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: role != 'USUARIO',
              child: Column(
                children: [
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HorasEncuestasPage(),
                        ),
                      );
                    },
                    child: const Text('RESUMEN DE HORAS REGISTRADAS'),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: role != 'USUARIO',
              child: Column(
                children: [
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListFormsScreen()),
                      );
                    },
                    child: Text('ADMINISTRAR ENCUESTAS'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListUsersScreen()),
                      );
                    },
                    child: Text('ADMINISTRAR USUARIOS'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListParameterScreen(param: 'Proyectos')),
                      );
                    },
                    child: Text('ADMINISTRAR PROYECTOS'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListParameterScreen(param: 'Actividades')),
                      );
                    },
                    child: Text('ADMINISTRAR ACTIVIDADES'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListParameterScreen(param: 'Cargos')),
                      );
                    },
                    child: Text('ADMINISTRAR CARGOS'),
                  ),
                  // ElevatedButton(
                  //   onPressed: () async {
                  //     sendEmail();
                      // try {
                      //   final accessToken = await getAccessToken();
                      //   await sendZohoEmail(
                      //     accessToken: accessToken,
                      //     fromEmail: 'javieruedase@zohomail.com',
                      //     toEmail: 'javieruedase@gmail.com',
                      //     subject: 'Prueba de correo',
                      //     content: 'contenido',
                      //   );
                      // } catch (e) {
                      //   print('Error: $e');
                      // }
                  //   },
                  //   child: Text('Enviar correo'),
                  // ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListParameterScreen(param: 'Profesiones')),
                      );
                    },
                    child: Text('ADMINISTRAR PROFESIONES'),
                  ),
                  Visibility(
                    visible: role != 'USUARIO',
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            html.window.open(
                              "https://app.powerbi.com/view?r=eyJrIjoiMzBiZGZjMGYtMjJlMy00NDhiLThlODUtNmE3Mzk3NjA1MWM2IiwidCI6IjJlZDU1NzRjLWY5YmEtNDQyNi05NjU4LWU0NzdhZDc0MzlkYiIsImMiOjR9",
                              '_blank',
                            );
                          },
                          child: Text('CONSULTAS'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String clientId = '1000.LJ685O4V2A3WG4C5KVHJL1HC12J54S';
  static const String clientSecret = 'b9bc37b1794fb1ade28605387d665fa7a515199685';
  static const String scope = 'ZohoMail.messages.CREATE';
  static const String redirectUri = 'https://cyma-encuestasmop.github.io/EncuestasMOP/';
  static const String accountId = '855887768';

  Future<String> getAccessToken() async {
  try {
    const authorizationUrl = 'https://accounts.zoho.com/oauth/v2/auth'
        '?scope=$scope'
        '&client_id=$clientId'
        '&response_type=code'
        '&access_type=offline'
        '&redirect_uri=$redirectUri';

    // Open the URL in a new tab/window
    js.context.callMethod('open', [authorizationUrl, '_blank']);

    // Use Completer to handle the asynchronous nature of window.onMessage
    final completer = Completer<String>();
    html.window.onMessage.listen((html.MessageEvent event) {
      if (event.data.toString().contains('code=')) {
        final authCode = Uri.parse(event.data.toString()).queryParameters['code'];
        if (authCode != null) {
          completer.complete(authCode);
        } else {
          completer.completeError('Authorization code not found in callback.');
        }
      }
    });

    final code = await completer.future;

    const tokenUrl = 'https://accounts.zoho.com/oauth/v2/token';
    final response = await http.post(
      Uri.parse(tokenUrl),
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'code': code,
      },
    );

    final accessToken = jsonDecode(response.body)['access_token'];
    print('Access Token: $accessToken');
    return accessToken;
  } catch (e) {
    print('Error in authentication: $e');
    throw Exception('Failed to authenticate with Zoho: $e');
  }
}



  Future<void> sendZohoEmail({
    required String accessToken,
    required String fromEmail,
    required String toEmail,
    String? ccEmail,
    String? bccEmail,
    required String subject,
    required String content,
    String? askReceipt,
  }) async {
    final url = Uri.parse('https://mail.zoho.com/api/accounts/$accountId/messages');

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Zoho-oauthtoken $accessToken',
    };

    final body = jsonEncode({
      'fromAddress': fromEmail,
      'toAddress': toEmail,
      'ccAddress': ccEmail ?? '',
      'bccAddress': bccEmail ?? '',
      'subject': subject,
      'content': content,
      'askReceipt': askReceipt ?? '',
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('Email sent successfully');
      } else {
        print('Failed to send email: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  Future<void> sendEmail() async {
    final url = Uri.parse(
      'https://v1.nocodeapi.com/javirueda7/zohomail/uQtvnhGfyoZKOpeY/sendEmail?fromAddress=javieruedase@zohomail.com&toAddress=thebucaracrew@gmail.com,javieruedase@gmail.com,javier.rueda7@outlook.com&content=contenido&subject=tema'
    );

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      print('Success: ${response.body}');
    } else {
      print('Failed: ${response.statusCode}');
    }
  }
}

