import 'package:flutter/material.dart';
import './company.dart';
import './database_helper.dart';
import 'dart:convert';


Map<String, bool> deserializeSelectedOptions(String jsonString) {
  return Map<String, bool>.from(jsonDecode(jsonString));
}
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dbHelper = DatabaseHelper();
  List<Company> _companies = [];

  final TextEditingController _nameFilterController = TextEditingController();
  final TextEditingController _classFilterController = TextEditingController();
  String _selectedClassification = '';

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  void _loadCompanies() async {
    final companies = await dbHelper.getCompanies(
      name: _nameFilterController.text,
      classification: _classFilterController.text
    );

    setState(() {
      _companies = companies;
    });
}


  void _editCompany(int id) async {
    final company = await dbHelper.getCompanyById(id);
    if (company != null) {
      final updatedCompany = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditCompanyScreen(company: company),
        ),
      );

      if (updatedCompany != null) {
        await dbHelper.updateCompany(updatedCompany);
        _loadCompanies();
      }
    } else {
      print('Empresa no encontrada con ID: $id');
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar esta empresa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              dbHelper.deleteCompany(id).then((_) => _loadCompanies());
              Navigator.pop(ctx);
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

// Método para mostrar los detalles de la empresa en un diálogo modal
void _showCompanyDetails(BuildContext context, Company company) {
  List<String> classifications = deserializeClassification(company.classification);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Detalles de la Empresa'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('* Nombre: ${company.name}'),
            Text('* URL: ${company.url}'),
            Text('* Teléfono: ${company.phone}'),
            Text('* Email: ${company.email}'),
            Text('* Productos y Servicios: ${company.products}'),
            SizedBox(height: 10),
            Text('Clasificaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
            // Mostrar las clasificaciones como una lista
            for (var classification in classifications)
              Text('- $classification'),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop(); // Cerrar el diálogo
          },
          child: Text('Cerrar'),
        ),
      ],
    ),
  );
}



List<String> deserializeClassification(String classification) {
  return classification.split(", ");
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Directorio de Empresas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameFilterController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                ),
                onChanged: (value) => _loadCompanies(),
              ),
              SizedBox(height: 16), // Espaciado entre filas
              TextField(
                controller: _classFilterController,
                decoration: InputDecoration(
                  labelText: 'Buscar por clasificación',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                ),
                onChanged: (value) => _loadCompanies(),
              ),
            ],
          ),  
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _companies.length,
              itemBuilder: (ctx, index) {
                final company = _companies[index];
                List<String> classifications = deserializeClassification(company.classification);
               
                return ListTile(
                  title: Text(company.name),
                  subtitle: Text(classifications.join(", ")), // Muestra las clasificaciones seleccionadas
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Evita que los botones usen todo el espacio horizontal
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.green), // Ícono de edición
                        onPressed: () {
                          // Lógica para editar la empresa
                          _editCompany(company.id!);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red), // Ícono de eliminación
                        onPressed: () => _confirmDelete(company.id!),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Mostrar una ventana modal con los detalles de la empresa
                    _showCompanyDetails(context, company);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCompanyScreen()),
          ).then((_) {
            // Llama a _loadCompanies para recargar la lista
            _loadCompanies();
          });
        },
        child: Icon(Icons.add),
        tooltip: 'Agregar Empresa',
        backgroundColor: const Color.fromARGB(255, 239, 250, 255),
      ),
    );
  }
}


class AddCompanyScreen extends StatefulWidget {
  @override
  _AddCompanyScreenState createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = "";
  String url ="";
  String phone = ""; 
  String email = "";
  String products = "";
  String classification = 'Consultoría';
  final List<String> options = ['Consultoría', 'Desarrollo a medida', 'Fábrica de software'];
   Map<String, bool> selectedOptions = {};

  @override
  void initState() {
    super.initState();
    // Inicializar todas las opciones como no seleccionadas
    selectedOptions = {for (var option in options) option: false};
  }


  String serializeSelectedOptions(Map<String, bool> selectedOptions) {
  List<String> selectedClassifications = selectedOptions.entries
      .where((entry) => entry.value == true)
      .map((entry) => entry.key)
      .toList();
  
  return selectedClassifications.join(", ");
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar Empresa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre de la Empresa'),
                onSaved: (value) => name = '$value',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'URL'),
                onSaved: (value) => url = '$value',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                onSaved: (value) => phone = '$value',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => email = '$value',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Productos y Servicios'),
                onSaved: (value) => products = '$value',
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0, bottom: 4.0), // Padding de 8 píxeles en todos los lados
                child: Text(
                  "Clasificación de la Empresa",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: ListView(
                  children: options.map((option) {
                    return CheckboxListTile(
                      title: Text(option),
                      value: selectedOptions[option],
                      onChanged: (bool? value) {
                        setState(() {
                          selectedOptions[option] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    String jsonString = serializeSelectedOptions(selectedOptions);
                    final company = Company(name: name, url: url, phone: phone, email: email, products: products, classification: jsonString);
                    // Aquí puedes guardar los datos en la base de datos SQLite
                    final id = await DatabaseHelper().insertCompany(company);
                    print('Empresa agregada con ID: $id');
                    Navigator.pop(context); // Regresa a la pantalla anterior
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class EditCompanyScreen extends StatefulWidget {
  final Company company;

  EditCompanyScreen({required this.company});

  @override
  _EditCompanyScreenState createState() => _EditCompanyScreenState();
}


class _EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String url;
  late String phone;
  late String email;
  late String products;
  late String selectedOptions;
  late List<String> selectedClassifications; // Lista para las opciones seleccionadas

  @override
  void initState() {
    super.initState();
    name = widget.company.name;
    url = widget.company.url;
    phone = widget.company.phone;
    email = widget.company.email;
    products = widget.company.products;
    selectedOptions = widget.company.classification;

    // Convertir el string de clasificaciones separadas por comas en una lista
    selectedClassifications = selectedOptions.split(', ').toList();
  }

  @override
  Widget build(BuildContext context) {
    // Definir las opciones posibles de clasificación
    List<String> allOptions = [
      "Consultoría",
      "Desarrollo a medida",
      "Fábrica de software",
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Editar Empresa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: 'Nombre de la Empresa'),
                onSaved: (value) => name = value!,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                initialValue: url,
                decoration: InputDecoration(labelText: 'URL'),
                onSaved: (value) => url = value!,
              ),
              TextFormField(
                initialValue: phone,
                decoration: InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                onSaved: (value) => phone = value!,
              ),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => email = value!,
              ),
              TextFormField(
                initialValue: products,
                decoration: InputDecoration(labelText: 'Productos y Servicios'),
                onSaved: (value) => products = value!,
              ),
               Padding(
                padding: EdgeInsets.only(top: 20.0, bottom: 4.0), 
                child: Text(
                  "Clasificación de la Empresa",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: ListView(
                  children: allOptions.map((option) {
                    return CheckboxListTile(
                      title: Text(option),
                      value: selectedClassifications.contains(option),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedClassifications.add(option);
                          } else {
                            selectedClassifications.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // Convertir la lista seleccionada en un string
                    selectedOptions = selectedClassifications.join(', ');

                    final updatedCompany = Company(
                      id: widget.company.id,
                      name: name,
                      url: url,
                      phone: phone,
                      email: email,
                      products: products,
                      classification: selectedOptions,
                    );
                    Navigator.pop(context, updatedCompany);
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

