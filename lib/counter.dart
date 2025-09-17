import 'package:flutter/material.dart';
import 'package:forms_app/services/encuestas_services.dart';

class HorasEncuestasPage extends StatefulWidget {
  const HorasEncuestasPage({super.key});

  @override
  State<HorasEncuestasPage> createState() => _HorasEncuestasPageState();
}

class _HorasEncuestasPageState extends State<HorasEncuestasPage> {
  late Future<Map<String, dynamic>> _futureData;
  final _service = EncuestasService();

  @override
  void initState() {
    super.initState();
    _futureData = _service.getEncuestasUsuariosHorasConGlobal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horas por Encuesta y Global')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final data = snapshot.data ?? {};
          final encuestas = (data['encuestas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final totalGlobal = (data['totalGlobalHoras'] as num?)?.toDouble() ?? 0.0;

          if (encuestas.isEmpty) {
            return const Center(child: Text('No hay datos para mostrar.'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Global
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Global de Horas (ENVIADA): ${totalGlobal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),

              // Lista de encuestas
              Expanded(
                child: ListView.separated(
                  itemCount: encuestas.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = encuestas[index];
                    final encuestaId = e['encuestaId']?.toString() ?? '—';
                    final totalEncuesta =
                        (e['totalHorasEncuesta'] as num?)?.toDouble() ?? 0.0;
                    final usuarios = (e['usuarios'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                    return ExpansionTile(
                      title: Text('Encuesta: $encuestaId'),
                      subtitle: Text('Total horas encuesta: ${totalEncuesta.toStringAsFixed(2)}'),
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: usuarios.length,
                          itemBuilder: (context, i) {
                            final u = usuarios[i];
                            final userId = u['userId']?.toString() ?? '—';
                            final totalUser =
                                (u['totalHorasUsuario'] as num?)?.toDouble() ?? 0.0;
                            final horasList = (u['horas'] as List?)?.cast<double>() ?? const [];

                            return ListTile(
                              title: Text('Usuario: $userId'),
                              subtitle: Text('Horas: ${horasList.join(', ')}'),
                              trailing: Text(
                                totalUser.toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
