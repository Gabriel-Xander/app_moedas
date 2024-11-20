import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(ConversorMoedasApp());
}

class ConversorMoedasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Conversor de Moedas',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: ConversorScreen(),
    );
  }
}

class ConversorScreen extends StatefulWidget {
  @override
  _ConversorScreenState createState() => _ConversorScreenState();
}

class _ConversorScreenState extends State<ConversorScreen> {
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _resultadoController = TextEditingController();

  String _moedaOrigem = 'USD';
  String _moedaDestino = 'BRL';
  List<String> _moedas = ['USD', 'BRL', 'EUR', 'JPY', 'GBP'];
  double? _taxa;

  bool _isLoading = false;

  Future<void> _fetchTaxaDeCambio() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = 'https://api.exchangerate-api.com/v4/latest/$_moedaOrigem';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final rates = jsonDecode(response.body)['rates'];
        setState(() {
          _taxa = rates[_moedaDestino];
          _converter();
        });
      } else {
        _showError('Erro ao buscar taxas de câmbio. Tente novamente.');
      }
    } catch (e) {
      _showError('Não foi possível se conectar ao servidor. Verifique sua conexão.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _converter() {
    final valor = double.tryParse(_valorController.text) ?? 0.0;

    if (_taxa != null) {
      final resultado = valor * _taxa!;
      _resultadoController.text = resultado.toStringAsFixed(2);
    } else {
      _resultadoController.text = '';
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _trocarMoedas() {
    setState(() {
      final temp = _moedaOrigem;
      _moedaOrigem = _moedaDestino;
      _moedaDestino = temp;
      _fetchTaxaDeCambio();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTaxaDeCambio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversor de Moedas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor em $_moedaOrigem',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => _converter(),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DropdownButton<String>(
                  value: _moedaOrigem,
                  items: _moedas.map((String moeda) {
                    return DropdownMenuItem<String>(
                      value: moeda,
                      child: Text(moeda),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _moedaOrigem = newValue!;
                      _fetchTaxaDeCambio();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: _trocarMoedas,
                ),
                DropdownButton<String>(
                  value: _moedaDestino,
                  items: _moedas.map((String moeda) {
                    return DropdownMenuItem<String>(
                      value: moeda,
                      child: Text(moeda),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _moedaDestino = newValue!;
                      _fetchTaxaDeCambio();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            _isLoading
                ? const CircularProgressIndicator()
                : TextField(
                    controller: _resultadoController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Resultado em $_moedaDestino',
                      border: const OutlineInputBorder(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
