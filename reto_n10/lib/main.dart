import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reto 10 -  API',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ApiConsumerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ApiConsumerScreen extends StatefulWidget {
  const ApiConsumerScreen({super.key});

  @override
  _ApiConsumerScreenState createState() => _ApiConsumerScreenState();
}

class _ApiConsumerScreenState extends State<ApiConsumerScreen> {
  final TextEditingController _queryController = TextEditingController();
  List<dynamic> _results = [];
  String? _rangoEdad, _estratoSocioeconomico, _perteneceAMinoria, _tieneDiscapacidad, _paisDestino, _nivelAcademico, _modalidad, _anioSeleccion, _genero;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

Future<void> fetchData([String parametro = ""]) async {
  final String baseUrl = 'https://www.datos.gov.co/resource/g85v-p2ik.json';
  final String url = parametro.isNotEmpty ? '$baseUrl?$parametro' : baseUrl;

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _results = json.decode(response.body);
      });
    } else {
      throw Exception('Error al cargar los datos');
    }
  } catch (e) {
    setState(() {
      _results = [{'error': 'No se pudo obtener la información'}];
    });
  }
}

void _openSettingsModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.zero, // Elimina el padding por defecto
        child: Column(
          mainAxisSize: MainAxisSize.max, // Asegura que la columna ocupe toda la altura
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Filtrar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField('Rango de Edad', (value) => _rangoEdad = value),
                    _buildTextField('Estrato Socioeconómico', (value) => _estratoSocioeconomico = value),
                    _buildTextField('Pertenece a Minoría', (value) => _perteneceAMinoria = value),
                    _buildTextField('Tiene Discapacidad', (value) => _tieneDiscapacidad = value),
                    _buildTextField('País de Destino', (value) => _paisDestino = value),
                    _buildTextField('Nivel Académico', (value) => _nivelAcademico = value),
                    _buildTextField('Modalidad', (value) => _modalidad = value),
                    _buildTextField('Año de Selección', (value) => _anioSeleccion = value),
                    _buildTextField('Género', (value) => _genero = value),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      String queryParams = _buildQueryParams();
                      fetchData(queryParams);
                      Navigator.of(context).pop();
                    },
                    child: Text('Aplicar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showGraphModal(context, _results.whereType<Map<String, dynamic>>().toList());
                    },
                    child: Text('Mostrar Gráficas'),
                  ),
                  TextButton(
                    onPressed: () {
                      _resetFilters();
                    },
                    child: Text('Restablecer filtros'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}


void _resetFilters() {
  FocusScope.of(context).unfocus();  // Desenfocar cualquier campo activo
  setState(() {
    _rangoEdad = '';
    _estratoSocioeconomico = '';
    _perteneceAMinoria = '';
    _tieneDiscapacidad = '';
    _paisDestino = '';
    _nivelAcademico = '';
    _modalidad = '';
    _anioSeleccion = '';
    _genero = '';
  });
}


String _buildQueryParams() {
  Map<String, String> params = {};

  if ((_rangoEdad ?? '').isNotEmpty) params['rango_de_edad'] = _rangoEdad!;
  if ((_estratoSocioeconomico ?? '').isNotEmpty) params['estrato_socioeconomico_de'] = _estratoSocioeconomico!;
  if ((_perteneceAMinoria ?? '').isNotEmpty) params['pertenece_a_minoria'] = _perteneceAMinoria!;
  if ((_tieneDiscapacidad ?? '').isNotEmpty) params['tiene_discapacidad'] = _tieneDiscapacidad!;
  if ((_paisDestino ?? '').isNotEmpty) params['pa_s_de_destino'] = _paisDestino!;
  if ((_nivelAcademico ?? '').isNotEmpty) params['nivel_acad_mico'] = _nivelAcademico!;
  if ((_modalidad ?? '').isNotEmpty) params['modalidad'] = _modalidad!;
  if ((_anioSeleccion ?? '').isNotEmpty) params['a_o_selecci_n'] = _anioSeleccion!;
  if ((_genero ?? '').isNotEmpty) params['g_nero'] = _genero!;

  return Uri(queryParameters: params).query; // Retorna la cadena de parámetros
}

void _showGraphModal(BuildContext context, List<Map<String, dynamic>> data) {
  try {
    if (data.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Gráficas de Datos'),
            content: Center(child: Text('No hay datos para mostrar.')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cerrar'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Contar cuántas becas hay por género
    Map<String, int> becasPorGenero = {};
    for (var item in data) {
      String genero = item['g_nero']?.toString().toLowerCase() ?? 'N/A';
      becasPorGenero[genero] = (becasPorGenero[genero] ?? 0) + 1;
    }

    // Obtener el valor máximo para definir un buen intervalo en el eje Y
    int maxValue = becasPorGenero.values.isNotEmpty ? becasPorGenero.values.reduce((a, b) => a > b ? a : b) : 1;
    double interval = (maxValue / 5).ceilToDouble(); // Se divide en 5 segmentos para mayor claridad

    // Convertir los datos a la estructura esperada por BarChart
    List<BarChartGroupData> barGroups = [];
    int index = 0;
    becasPorGenero.forEach((genero, cantidad) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: cantidad.toDouble(),
              color: Colors.blue,
              width: 30, // Aumentar grosor de barras
              borderRadius: BorderRadius.circular(5),
              rodStackItems: [],
              // Mostrar los valores sobre las barras
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue.toDouble(),
                color: Colors.grey.shade300,
              ),
            ),
          ],
          showingTooltipIndicators: [0], // Muestra el valor encima de la barra
        ),
      );
      index++;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Gráficas de Datos'),
          content: SizedBox(
            height: 350,
            width: 600,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: barGroups,
                gridData: FlGridData(show: true), // Mostrar líneas de la cuadrícula
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval, // Ajustar espaciado de valores en Y
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(value.toInt().toString(), style: TextStyle(fontSize: 12));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() < 0 || value.toInt() >= becasPorGenero.keys.length) {
                          return Text('N/A');
                        }
                        return Text(
                          becasPorGenero.keys.elementAt(value.toInt()),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  } catch (e, stacktrace) {
    print('Error en _showGraphModal: $e');
    print(stacktrace);
  }
}


List<BarChartGroupData> _generateBarGroups(List<Map<String, dynamic>> data) {
  return data.asMap().entries.map((entry) {
    return BarChartGroupData(
      x: entry.key,
      barRods: [
        BarChartRodData(
          toY: (entry.value['valor'] is num) ? entry.value['valor'].toDouble() : 0.0,
          color: Colors.blue,
        ),
      ],
    );
  }).toList();
}
 
  Widget _buildTextField(String label, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        autofocus: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Becas en el exterior'),
        leading: IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => _openSettingsModal(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: _results.isNotEmpty && _results[0] is Map
                  ? (_results[0] as Map<String, dynamic>)
                      .keys
                      .map((key) => DataColumn(label: Text(key)))
                      .toList()
                  : [DataColumn(label: Text('Datos'))],
              rows: _results
                  .map((row) => DataRow(
                        cells: row is Map
                            ? row.values.map((value) => DataCell(Text(value.toString()))).toList()
                            : [DataCell(Text(row.toString()))],
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
