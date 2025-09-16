import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  num? totalHoras;
  bool loading = false;
  String? errorMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horas ENVIADAS')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FilledButton.icon(
              icon: loading
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.calculate),
              onPressed: loading ? null : _sumarHoras, 
              label: Text(loading ? 'Calculando…' : 'Sumar horas'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total de horas ENVIADAS', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      totalHoras?.toString() ?? '—',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sumarHoras() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final fs = FirebaseFirestore.instance;
      final encuestasSnap = await fs.collection('Encuestas').get();

      num total = 0;

      for (final encuesta in encuestasSnap.docs) {
        final usuariosRef = encuesta.reference.collection('Usuarios');
        final usuariosSnap =
            await usuariosRef.where('status', isEqualTo: 'ENVIADA').get();

        for (final u in usuariosSnap.docs) {
          final data = u.data();
          final answer = data['answer'];
          total += _sumHorasFromAnswer(answer);
        }
      }

      setState(() => totalHoras = total);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Total de horas ENVIADAS: $total')),
        );
      }
    } catch (e) {
      setState(() => errorMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  num _sumHorasFromAnswer(dynamic answer) {
    if (answer == null || answer is! String) return 0;

    num total = 0;
    final entries = answer.split(';');

    for (var raw in entries) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final clean = line.startsWith('?') ? line.substring(1) : line;
      final pairs = clean.split('&');

      for (final pair in pairs) {
        if (pair.startsWith('horas=')) {
          final valueStr = pair.split('=').skip(1).join('=').trim();
          final v = num.tryParse(valueStr.replaceAll(',', '.'));
          if (v != null) total += v;
        }
      }
    }
    return total;
  }
}
