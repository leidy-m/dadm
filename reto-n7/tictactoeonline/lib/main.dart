import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // Options to run debug Chrome
    options: FirebaseOptions(
      apiKey: "x",
      authDomain: "x",
      databaseURL: "x",  
      projectId: "x",
      storageBucket: "x",
      messagingSenderId: "x",
      appId: "x",
      measurementId: "x"
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.dark, 
      /* ThemeMode.system to follow system theme, 
         ThemeMode.light for light theme, 
         ThemeMode.dark for dark theme
      */
      theme: ThemeData(
        brightness: Brightness.light,
        /* light theme settings */
      ),
      debugShowCheckedModeBanner: false,
      title: 'Tic-Tac-Toe Online',
      home: GameListScreen(),
    );
  }
}

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  _GameListScreenState createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  final DatabaseReference _gamesRef =
      FirebaseDatabase.instance.ref().child('games');
  List<Map<String, dynamic>> _games = [];

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  void _fetchGames() {
    _gamesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _games = data.entries.map((entry) {
            return {
              'id': entry.key,
              'player1': entry.value['player1'],
              'player2': entry.value['player2'],
            };
          }).toList();
        });
      }
    });
  }

  void _createGame() async {
    final newGameRef = _gamesRef.push();
     final gameId = newGameRef.key;
    await newGameRef.set({
      'id': gameId,
      'player1': 'Player 1',
      'player2': null,
      'board': List.generate(3, (_) => List.generate(3, (_) => '')),
      'turn': 'player1',
      'status': 'waiting',
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(gameId: newGameRef.key!, isPlayer1: true),
      ),
    );
  }

  void _joinGame(String gameId) async {
    final gameRef = _gamesRef.child(gameId);
    await gameRef.update({'player2': 'Player 2'});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(gameId: gameId, isPlayer1: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('-- Juegos disponibles --')),
      body: ListView.builder(
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return ListTile(
            title: Text('Juego ${game['id'] ?? 'Unknown'}'),
            subtitle: Text(game['player2'] == null ? 'Estado: Esperando al jugador 2' : 'Estado: Juego lleno'),
            onTap: game['player2'] == null ? () => _joinGame(game['id']) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (game['player2'] == null)
                  IconButton(
                    icon: Icon(Icons.person_add, color: Colors.cyan),
                    onPressed: () => _joinGame(game['id']),
                    tooltip: 'Unirse al juego',
                  ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteGame(game['id']),
                  tooltip: 'Eliminar juego',
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGame,
        child: Icon(Icons.add),
      ),
    );
  }
}

void _deleteGame(String? gameId) {
  if (gameId == null) {
    print('Error: El ID del juego no es válido');
    return;
  }

  final gameRef = FirebaseDatabase.instance.ref().child('games/$gameId');
  gameRef.remove().then((_) {
    print('Juego eliminado exitosamente');
  }).catchError((error) {
    print('Error al eliminar el juego: $error');
  });
}

class GameScreen extends StatefulWidget {
  final String gameId;
  final bool isPlayer1;

  const GameScreen({super.key, required this.gameId, required this.isPlayer1});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late DatabaseReference _gameRef;
  late List<List<String>> _board;
  late String _turn;
  late String _status;

  @override
  void initState() {
    super.initState();

    // Inicializa la referencia al juego
    _gameRef = FirebaseDatabase.instance.ref().child('games/${widget.gameId}');

    // Inicializa los valores predeterminados de las variables
    _board = List.generate(3, (_) => List.generate(3, (_) => '')); // Tablero vacío
    _turn = 'player1'; // Turno inicial predeterminado
    _status = 'waiting'; // Estado inicial predeterminado

    // Escucha los cambios en la base de datos
    _listenToGameChanges();
  }

  void _listenToGameChanges() {
    _gameRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _board = List<List<String>>.from(
              data['board'].map((row) => List<String>.from(row)));
          _turn = data['turn'] as String;
          _status = data['status'] as String;
        });
      }
    });
  }

  void _makeMove(int row, int col) async {
  if (_board[row][col].isEmpty &&
      ((_turn == 'player1' && widget.isPlayer1) ||
          (_turn == 'player2' && !widget.isPlayer1))) {
    setState(() {
      _board[row][col] = widget.isPlayer1 ? 'X' : 'O';
      _turn = widget.isPlayer1 ? 'player2' : 'player1';
    });
    await _gameRef.update({'board': _board, 'turn': _turn});

    // Verificar el estado del juego
    String winner = _checkWinner();
    if (winner != '') {
      _showEndGameDialog('Jugador $winner gana!');
    } else if (_isDraw()) {
      _showEndGameDialog('¡Es un empate!');
    }
  }
}

String _checkWinner() {
  // Verifica las filas, columnas y diagonales
  for (int i = 0; i < 3; i++) {
    // Comprobar filas
    if (_board[i][0] == _board[i][1] && _board[i][1] == _board[i][2] && _board[i][0] != '') {
      return _board[i][0]; // Retorna 'X' o 'O'
    }
    // Comprobar columnas
    if (_board[0][i] == _board[1][i] && _board[1][i] == _board[2][i] && _board[0][i] != '') {
      return _board[0][i];
    }
  }

  // Comprobar diagonales
  if (_board[0][0] == _board[1][1] && _board[1][1] == _board[2][2] && _board[0][0] != '') {
    return _board[0][0];
  }
  if (_board[0][2] == _board[1][1] && _board[1][1] == _board[2][0] && _board[0][2] != '') {
    return _board[0][2];
  }

  return ''; // Si no hay ganador
}

bool _isDraw() {
  // Verifica si todas las celdas están llenas y no hay ganador
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      if (_board[i][j].isEmpty) {
        return false; // Si hay al menos una celda vacía, no es empate
      }
    }
  }
  return true; // Si no hay celdas vacías y no hay ganador, es empate
}

void _showEndGameDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Juego Terminado'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Aceptar'),
            onPressed: () {
              Navigator.of(context).pop();
              // Reiniciar el juego o navegar a otra pantalla si es necesario
            },
          ),
        ],
      );
    },
  );
}


Widget _buildBoard() {
  final cellSize = 80.0; // Tamaño fijo para las celdas

  return SizedBox(
    width: cellSize * 3 + 8.0, // El ancho total de la cuadrícula con espaciado
    height: cellSize * 3 + 8.0, // El alto total de la cuadrícula con espaciado
    child: GridView.count(
      crossAxisCount: 3, // Tres columnas
      childAspectRatio: 1, // Hace que las celdas sean cuadradas
      mainAxisSpacing: 4.0, // Espaciado entre filas
      crossAxisSpacing: 4.0, // Espaciado entre columnas
      shrinkWrap: true, // Ajusta el tamaño del GridView al contenido
      children: List.generate(9, (index) {
        final row = index ~/ 3;
        final col = index % 3;

        return GestureDetector(
          onTap: () => _makeMove(row, col),
          child: Container(
            width: cellSize, // Establece el ancho de la celda
            height: cellSize, // Establece el alto de la celda
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(255, 255, 0, 238)),
            ),
            alignment: Alignment.center,
            child: _board[row][col].isEmpty
                ? null
                : FittedBox(
                    fit: BoxFit.contain, // Ajusta la imagen dentro del espacio
                    child: Image.asset(
                      _board[row][col] == 'X'
                          ? 'images/x_marker.png'
                          : 'images/o_marker.png',
                    ),
                  ),
          ),
        );
      }),
    ),
  );
}



  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Juego ${widget.gameId}')),
    body: Center( // Centra todo el contenido en el cuerpo
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // Asegura que los elementos hijos estén centrados
        children: [
          _buildBoard(),
          SizedBox(height: 16), // Espacio entre el tablero y el texto
          Text('Turno: ${_turn == 'player1' ? 'Jugador 1' : 'Jugador 2'}'),
        ],
      ),
    ),
  );
}

}