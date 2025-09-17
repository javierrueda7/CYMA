import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para obtener horas desde las encuestas/usuarios en Firestore.
/// - Incluye TODAS las encuestas (no se filtra por status de encuesta)
/// - Solo considera usuarios con status == "ENVIADA" y answer no vacío
/// - Extrae todas las horas desde 'answer' (múltiples registros separados por ';')
/// - Devuelve: lista de encuestas con horas por usuario y total por encuesta,
///   además de 'totalGlobalHoras'.
class EncuestasService {
  final FirebaseFirestore db;

  EncuestasService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  /// Llama a esta función para obtener:
  /// {
  ///   'encuestas': [
  ///     {
  ///       'encuestaId': String,
  ///       'usuarios': [
  ///         { 'userId': String, 'horas': List<double>, 'totalHorasUsuario': double }
  ///       ],
  ///       'totalHorasEncuesta': double
  ///     },
  ///     ...
  ///   ],
  ///   'totalGlobalHoras': double
  /// }
  Future<Map<String, dynamic>> getEncuestasUsuariosHorasConGlobal() async {
    final List<Map<String, dynamic>> resultList = [];
    double totalGlobalHoras = 0.0;

    final CollectionReference encuestasCollection = db.collection('Encuestas');
    final QuerySnapshot encuestasSnapshot = await encuestasCollection.get();

    for (final encuestaDoc in encuestasSnapshot.docs) {
      final CollectionReference usuariosCollection =
          encuestaDoc.reference.collection('Usuarios');
      final QuerySnapshot usuariosSnapshot = await usuariosCollection.get();

      double totalHorasEncuesta = 0.0;
      final usuarios = <Map<String, dynamic>>[];

      for (final doc in usuariosSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>? ?? {};
        final status = userData['status'];
        final answer = (userData['answer'] ?? '').toString().trim();

        if (status == 'ENVIADA' && answer.isNotEmpty) {
          final horasList = _extractHorasList(answer);
          if (horasList.isNotEmpty) {
            final totalUser = horasList.fold<double>(0.0, (a, b) => a + b);
            totalHorasEncuesta += totalUser;

            usuarios.add({
              'userId': doc.id,
              'horas': horasList,
              'totalHorasUsuario': totalUser,
            });
          }
        }
      }

      if (usuarios.isNotEmpty) {
        resultList.add({
          'encuestaId': encuestaDoc.id,
          'usuarios': usuarios,
          'totalHorasEncuesta': totalHorasEncuesta,
        });
        totalGlobalHoras += totalHorasEncuesta;
      }
    }

    // Ordena por id de encuesta en descendente (opcional)
    resultList.sort((a, b) => b['encuestaId'].compareTo(a['encuestaId']));

    return {
      'encuestas': resultList,
      'totalGlobalHoras': totalGlobalHoras,
    };
  }

  /// Extrae todas las horas presentes en un string `answer`.
  /// Soporta múltiples registros separados por `;` y formatos como:
  /// ?idencuesta=E0001&...&horas=16&fecha=...;?idencuesta=...&horas=3
  List<double> _extractHorasList(String answer) {
    final List<double> horas = [];
    if (answer.isEmpty) return horas;

    // Divide por posibles múltiples bloques
    final registros = answer.split(';');

    // Busca el parámetro horas=...
    final horasRegex = RegExp(r'(^|[?&])horas=([^&;]+)');

    for (final reg in registros) {
      final match = horasRegex.firstMatch(reg);
      if (match != null) {
        final raw = match.group(2)?.trim() ?? '';
        // Normaliza coma decimal -> punto
        final normalized = raw.replaceAll(',', '.');
        final value = double.tryParse(normalized);
        if (value != null) horas.add(value);
      }
    }
    return horas;
  }
}
