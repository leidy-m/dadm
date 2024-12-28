import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import './company.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'companies.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE companies(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            url TEXT,
            phone TEXT,
            email TEXT,
            products TEXT,
            classification TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  Future<int> insertCompany(Company company) async {
    final db = await database;
    return db.insert('companies', company.toMap());
  }

  Future<List<Company>> getCompanies({String? name, String? classification}) async {
    final db = await database;
    String whereClause = '';
    List<String> whereArgs = [];

    if (name != null && name.isNotEmpty) {
      whereClause += 'name LIKE ?';
      whereArgs.add('%$name%');
    }

    if (classification != null && classification.isNotEmpty) {
      // if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'classification LIKE ?';
      whereArgs.add('%$classification%');
    }

    final maps = await db.query(
      'companies',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
    
    print("--------------------maps");
    print(maps);

    return List.generate(maps.length, (i) => Company.fromMap(maps[i]));
  }

  Future<int> updateCompany(Company company) async {
    final db = await database;
    return db.update('companies', company.toMap(), where: 'id = ?', whereArgs: [company.id]);
  }

  Future<int> deleteCompany(int id) async {
    final db = await database;
    return db.delete('companies', where: 'id = ?', whereArgs: [id]);
  }

  Future<Company?> getCompanyById(int id) async {
  final db = await database;
  final result = await db.query(
    'companies', // Nombre de la tabla
    where: 'id = ?', // Condición para buscar por ID
    whereArgs: [id], // Valor del ID
  );

  if (result.isNotEmpty) {
    return Company.fromMap(result.first);
  } else {
    return null; // Si no se encuentra ninguna empresa con ese ID
  }
}
}
