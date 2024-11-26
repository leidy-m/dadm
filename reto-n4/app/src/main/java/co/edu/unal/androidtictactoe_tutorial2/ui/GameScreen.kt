package co.edu.unal.androidtictactoe_tutorial2.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.ViewModel
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.ui.platform.LocalContext
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.runtime.Composable
import android.app.Activity
import co.edu.unal.androidtictactoe_tutorial2.R
import kotlin.random.Random
import androidx.compose.ui.res.painterResource

// ViewModel to manage Game State
class GameViewModel : ViewModel() {

    // Represents the board
    private val _board = mutableStateListOf(
        mutableStateListOf("", "", ""),
        mutableStateListOf("", "", ""),
        mutableStateListOf("", "", "")
    )
    val board: List<List<String>> = _board

    var currentPlayer by mutableStateOf("X")  // "X" es el jugador, "O" es Android
        private set

    var winner by mutableStateOf<String?>(null)
        private set

    var isTie by mutableStateOf(false)  // Estado para verificar si es empate
        private set

    // Estadísticas del juego
    var playerWins by mutableStateOf(0)
        private set
    var aiWins by mutableStateOf(0)
        private set
    var ties by mutableStateOf(0)
        private set

    // Dificultad seleccionada
    var difficulty by mutableStateOf("Fácil")
        private set

    init {
        currentPlayer = "X"
    }

    fun confDif(selectedDifficulty: String) {
        difficulty = selectedDifficulty
    }

    fun makeMove(row: Int, col: Int) {
        if (board[row][col].isEmpty() && winner == null && !isTie) {
            _board[row][col] = currentPlayer
            if (checkWinner()) {
                winner = currentPlayer
                updateStats()
            } else if (boardIsFull()) {
                isTie = true
                ties += 1
            } else {
                currentPlayer = if (currentPlayer == "X") "O" else "X"
                if (currentPlayer == "O") { // Turno de Android
                    makeIATurn()
                }
            }
        }
    }

    fun resetGame() {
        // Limpiar el tablero
        for (row in _board) {
            row.fill("")
        }
        // Alternar quién empieza
        currentPlayer = if (Random.nextBoolean()) "X" else "O"
        winner = null
        isTie = false
    }

    private fun checkWinner(): Boolean {
        for (i in 0..2) {
            if (_board[i][0] == currentPlayer && _board[i][1] == currentPlayer && _board[i][2] == currentPlayer) return true
            if (_board[0][i] == currentPlayer && _board[1][i] == currentPlayer && _board[2][i] == currentPlayer) return true
        }
        if (_board[0][0] == currentPlayer && _board[1][1] == currentPlayer && _board[2][2] == currentPlayer) return true
        if (_board[0][2] == currentPlayer && _board[1][1] == currentPlayer && _board[2][0] == currentPlayer) return true
        return false
    }

    private fun boardIsFull(): Boolean {
        return _board.all { row -> row.all { it.isNotEmpty() } }
    }

    private fun makeIATurn() {
        when (difficulty) {
            "Fácil" -> makeRandomMove()  // Movimiento aleatorio
            "Medio" -> {
                val blockingMove = findWinningMove("Player")
                if (blockingMove != null) {
                    makeMove(blockingMove.first, blockingMove.second)  // Bloquea el jugador
                } else {
                    makeRandomMove()  // Movimiento aleatorio si no se necesita bloquear
                }
            }
            "Difícil" -> {
                val winningMove = findWinningMove("IA")
                if (winningMove != null) {
                    makeMove(winningMove.first, winningMove.second)  // Gana si puede
                } else {
                    val blockingMove = findWinningMove("Player")
                    if (blockingMove != null) {
                        makeMove(blockingMove.first, blockingMove.second)  // Bloquea al jugador si puede
                    } else {
                        makeStrategicMove()  // Movimiento estratégico
                    }
                }
            }
        }
    }

    // Movimiento aleatorio
    private fun makeRandomMove() {
        val emptyPositions = mutableListOf<Pair<Int, Int>>()
        for (i in _board.indices) {
            for (j in _board[i].indices) {
                if (_board[i][j].isEmpty()) {
                    emptyPositions.add(Pair(i, j))
                }
            }
        }
        if (emptyPositions.isNotEmpty()) {
            val randomMove = emptyPositions[Random.nextInt(emptyPositions.size)]
            makeMove(randomMove.first, randomMove.second)
        }
    }

    // Encuentra un movimiento ganador o de bloqueo
    private fun findWinningMove(player: String): Pair<Int, Int>? {
        for (i in _board.indices) {
            for (j in _board[i].indices) {
                if (_board[i][j].isEmpty()) {
                    _board[i][j] = player // Simula el movimiento
                    if (checkWinner()) {
                        _board[i][j] = "" // Restaura el tablero
                        return Pair(i, j)
                    }
                    _board[i][j] = "" // Restaura el tablero
                }
            }
        }
        return null
    }

    // Movimiento para dificultad difícil
    private fun makeStrategicMove() {
        val center = Pair(1, 1)
        val corners = listOf(Pair(0, 0), Pair(0, 2), Pair(2, 0), Pair(2, 2))
        val emptyPositions = mutableListOf<Pair<Int, Int>>()

        for (i in _board.indices) {
            for (j in _board[i].indices) {
                if (_board[i][j].isEmpty()) {
                    emptyPositions.add(Pair(i, j))
                }
            }
        }

        if (emptyPositions.contains(center)) {
            makeMove(center.first, center.second)
            return
        }

        for (corner in corners) {
            if (emptyPositions.contains(corner)) {
                makeMove(corner.first, corner.second)
                return
            }
        }

        if (emptyPositions.isNotEmpty()) {
            val randomMove = emptyPositions[Random.nextInt(emptyPositions.size)]
            makeMove(randomMove.first, randomMove.second)
        }
    }

    private fun updateStats() {
        when (winner) {
            "X" -> playerWins += 1
            "O" -> aiWins += 1
        }
    }
}

@Composable
fun GameScreen(viewModel: GameViewModel = viewModel()) {
    val context = LocalContext.current
    val activity = context as? Activity
    var expanded by remember { mutableStateOf(false) } // Control para el menú desplegable

    val playerWins = viewModel.playerWins
    val aiWins = viewModel.aiWins
    val ties = viewModel.ties
    val totalGames = playerWins + aiWins + ties

    val currentPlayer = viewModel.currentPlayer
    val board = viewModel.board
    val winner = viewModel.winner
    val isTie = viewModel.isTie
    val difficulty = viewModel.difficulty

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(4.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Título del juego
        Text(text = "** Tic-Tac-Toe **")

        Spacer(modifier = Modifier.height(16.dp))

        // Opciones con iconos
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Opción: Nuevo Juego
            Button(onClick = { viewModel.resetGame() },
                modifier = Modifier
                    .padding(1.dp),
                shape = RoundedCornerShape(4.dp), // Bordes redondeados
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFFa2008c), // Fondo azul personalizado
                    contentColor = Color.White // Color del texto e ícono
                )) {
                Column(
                    modifier = Modifier
                        .padding(4.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {

                    Icon(imageVector = Icons.Default.Refresh, contentDescription = "Nuevo Juego")
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(text = "Nuevo Juego")
                }
            }

            // Opción: Dificultad
            Button(onClick = { expanded = !expanded }) {
                Icon(imageVector = Icons.Default.Settings, contentDescription = "Dificultad")
                Spacer(modifier = Modifier.width(8.dp))
                Text(difficulty)
            }

            ExitButton(activity = activity)
        }

        // Menú desplegable para seleccionar dificultad
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            listOf("Fácil", "Medio", "Difícil").forEach {
                DropdownMenuItem({ Text(it) },
                    onClick = {
                        viewModel.confDif(it)
                        expanded = false
                    })
            }
        }

        // Tablero de juego
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            for (i in board.indices) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    for (j in board[i].indices) {
                        var color = Color.Green
                        if ( board[i][j]== "O" ) {
                            color = Color.Red
                        }
                        Button(
                            modifier = Modifier
                                .size(100.dp)
                                .padding(1.dp),
                            onClick = {
                                viewModel.makeMove(i, j)
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = Color.Gray),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(
                                text = board[i][j],
                                color = color
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Mostrar estadísticas
        Text("Total de juegos: $totalGames")
        Text("Victorias Jugador (X): $playerWins")
        Text("Victorias Android (O): $aiWins")
        Text("Empates: $ties")

        // Mostrar resultado de la partida
        winner?.let {
            Text(text = "¡Ganador: ${if (it == "X") "Humano" else "Android"}!")
        }
        if (isTie) {
            Text("¡Empate!")
        }

        Spacer(modifier = Modifier.height(16.dp))

        ButtonWithDialog()
    }
}



@Composable
fun ExitButton(activity: Activity?) {
    // Estado para mostrar el diálogo
    var showDialog by remember { mutableStateOf(false) }

    // Botón de "Salir"
    Button(
        onClick = { showDialog = true },
        modifier = Modifier.padding(8.dp),
        shape = RoundedCornerShape(4.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = Color(0xFFa2008c), // Fondo morado
            contentColor = Color.White // Texto e ícono blanco
        )
    ) {
        Column(
            modifier = Modifier.padding(4.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(imageVector = Icons.Default.ExitToApp, contentDescription = "Salir")
            Spacer(modifier = Modifier.height(4.dp))
            Text(text = "Salir")
        }
    }

    // Diálogo de confirmación
    if (showDialog) {
        AlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text(text = "Confirmación") },
            text = { Text(text = "¿Seguro que deseas salir de la aplicación?") },
            confirmButton = {
                TextButton(onClick = {
                    activity?.finish() // Cierra la actividad
                }) {
                    Text(text = "Sí", color = Color.Red)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDialog = false }) {
                    Text(text = "No")
                }
            }
        )
    }

}




@Composable
fun ButtonWithDialog() {
    // Variable para controlar si se muestra el diálogo
    var showDialog by remember { mutableStateOf(false) }

    // Botón principal
    Button(
        onClick = { showDialog = true }, // Al hacer clic, mostramos el diálogo
        modifier = Modifier.padding(8.dp),
        shape = RoundedCornerShape(8.dp), // Bordes redondeados
        colors = ButtonDefaults.buttonColors(
            containerColor = Color(0xFF6200EE), // Color morado personalizado
            contentColor = Color.White // Color del texto e ícono
        )
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Ícono desde un recurso PNG
            Icon(
                painter = painterResource(id = R.drawable.path28), // Cambia al recurso correcto
                contentDescription = "Icono personalizado",
                modifier = Modifier.size(48.dp) // Tamaño del ícono
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(text = "Acerca de")
        }
    }

    // Diálogo emergente
    if (showDialog) {
        AlertDialog(
            onDismissRequest = { showDialog = false }, // Cerrar diálogo al hacer clic fuera
            title = {
                Text(text = "Información")
            },
            text = {
                Text(text = "Estudiante = Leidy \nDesarrollo de Aplicaciones Móviles")
            },
            confirmButton = {
                Button(
                    onClick = { showDialog = false } // Ocultar el diálogo al hacer clic
                ) {
                    Text("Cerrar")
                }
            }
        )
    }
}