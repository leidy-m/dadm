package co.edu.unal.androidtictactoe_tutorial2.ui

// import androidx.compose.foundation.background
// import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
// import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
// import androidx.compose.foundation.border
import androidx.lifecycle.ViewModel
import kotlin.random.Random
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

    init {
        // Inicializamos el primer jugador al azar
        currentPlayer = if (Random.nextBoolean()) "X" else "O"
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
        // Comprobar filas, columnas y diagonales
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
        // Lógica simple de la IA: elige una casilla vacía al azar
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

    // Actualizar estadísticas del juego
    private fun updateStats() {
        when (winner) {
            "X" -> playerWins += 1
            "O" -> aiWins += 1
        }
    }
}

@Composable
fun GameCell(value: String, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .size(100.dp)
            .height(100.dp),
        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.tertiary)
    ) {
        Text(text = value)
    }
}

@Composable
fun GameScreen(viewModel: GameViewModel = viewModel()) {
    val playerWins = viewModel.playerWins
    val aiWins = viewModel.aiWins
    val ties = viewModel.ties
    val totalGames = playerWins + aiWins + ties // Total de juegos jugados

    val currentPlayer = viewModel.currentPlayer
    val board = viewModel.board
    val winner = viewModel.winner
    val isTie = viewModel.isTie

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Título del juego
        Text(text = "Tic-Tac-Toe")

        Spacer(modifier = Modifier.height(16.dp))

        // Estadísticas
        Text(text = "Juegos Jugados = $totalGames")
        Text(text = "Victorias del Jugador = $playerWins")
        Text(text = "Victorias de Android = $aiWins")
        Text(text = "Empates = $ties")

        Spacer(modifier = Modifier.height(32.dp))

        // Mostrar el tablero de juego
        Column {
            for (i in 0..2) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    for (j in 0..2) {
                        GameCell(
                            value = board[i][j],
                            onClick = {
                                // Llamar al método de hacer jugada
                                viewModel.makeMove(i, j)
                            }
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Mostrar el estado del juego (ganador o empate)
        if (winner != null) {
            Text(text = "¡Ganador: ${if (winner == "X") "Humano" else "Android"}!")
        } else if (isTie) {
            Text(text = "¡Es un empate!")
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Botón para reiniciar el juego
        Button(onClick = { viewModel.resetGame() }) {
            Text(text = "Reiniciar Juego")
        }
    }
}


@Preview(showBackground = true)
@Composable
fun TicTacToePreview() {
    GameScreen()
}
