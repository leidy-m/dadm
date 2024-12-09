package co.edu.unal.androidtictactoe_tutorial2.ui

import android.app.Activity
import android.content.Context
import android.media.SoundPool
import android.os.Handler
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import co.edu.unal.androidtictactoe_tutorial2.MainActivity
import co.edu.unal.androidtictactoe_tutorial2.R
import kotlin.random.Random

import androidx.compose.ui.platform.LocalConfiguration


class GameViewModel : ViewModel() {
    private lateinit var soundPool: SoundPool
    private var soundId: Int = 0
    private lateinit var mainActivity : MainActivity

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
                    val handler = Handler()
                    handler.postDelayed(
                        {    makeIATurn() },
                        1 * 100
                    ) // afterDelay will be executed after (secs*1000)

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
                    makeMove(winningMove.first, winningMove.second)
                } else {
                    val blockingMove = findWinningMove("Player")
                    if (blockingMove != null) {
                        makeMove(blockingMove.first, blockingMove.second)
                    } else {
                        makeStrategicMove()
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
fun GameScreen(viewModel: GameViewModel = viewModel(), context: Context ) {

    // Inicio del sonido -- 01122024
    val soundPool: SoundPool = SoundPool.Builder()
        .setMaxStreams(1)
        .build()
    var soundId: Int = 0
    val objMainAct = MainActivity()
    SoundPool.Builder()
        .setMaxStreams(1) // Número máximo de sonidos simultáneos
        .build()
    soundId = soundPool.load(context.applicationContext, R.raw.shine, 1)
    // soundPool.play(soundId, 1f, 1f, 0, 0, 1f)
    // Fin del sonido -- 01122024

    // Inicio del giro de la pantalla
    val configuration = LocalConfiguration.current
    val isPortrait = configuration.orientation == android.content.res.Configuration.ORIENTATION_PORTRAIT


    // val context = LocalContext.current
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

    // Título del juego
    if (isPortrait) { Text(text = "** Tic-Tac-Toe **") }
    if (isPortrait) { Spacer(modifier = Modifier.height(16.dp)) }
    val btnPadding = if (isPortrait) 4.dp else 1.dp

    val btnSize = if (isPortrait) 100.dp else 79.dp

    Spacer(modifier = Modifier.height(100.dp))

    // Tablero de juego
    Column(
        modifier = Modifier.fillMaxWidth().padding(1.dp, 50.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        for (i in board.indices) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                for (j in board[i].indices) {
                    Button(
                        modifier = Modifier
                            .size(btnSize).padding(4.dp),
                        onClick = {
                            viewModel.makeMove(i, j); soundPool.play(soundId, 1f, 1f, 0, 0, 1f)
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color.Gray),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        when (board[i][j]) {
                            "X" -> Image(
                                painter = painterResource(id = R.drawable.x_marker),
                                contentDescription = "Jugador X",
                            )
                            "O" -> Image(
                                painter = painterResource(id = R.drawable.o_marker),
                                contentDescription = "Jugador O",
                            )
                            else -> Spacer(modifier = Modifier.size(64.dp)) // Espacio vacío
                        }
                    }
                }
            }
        }

    }
    val statsPadding = if (isPortrait) 20.dp else 120.dp

    Column (
        modifier = Modifier.fillMaxWidth().padding(statsPadding, 2.dp),
        verticalArrangement = Arrangement.Center
    ) {
        winner?.let {
            Text(text = "¡Ganador: ${if (it == "X") "Humano" else "Android"}!")
        }
        if (isTie) {
            Text("¡Empate!")
        }
        Text("Total de juegos: $totalGames")
        Text("Victorias Jugador: $playerWins")
        Text("Victorias Android: $aiWins")
        Text("Empates: $ties")
    }



    val bottomIconsPadding = if (isPortrait) 110.dp else 60.dp

    // Opciones con iconos
    Row(
        modifier = Modifier.fillMaxWidth().padding(1.dp, bottomIconsPadding),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.Bottom
    ) {
        // Opción: Nuevo Juego
        Button(onClick = { viewModel.resetGame() },
            modifier = Modifier
                .padding(1.dp),
            shape = RoundedCornerShape(btnPadding), // Bordes redondeados
            colors = ButtonDefaults.buttonColors(
                containerColor = Color(0xFFa2008c), // Fondo rosado personalizado
                contentColor = Color.White // Color del texto e ícono
            )) {
            Column(
                modifier = Modifier
                    .padding(btnPadding),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {

                if (isPortrait) { Icon(imageVector = Icons.Default.Refresh, contentDescription = "Nuevo Juego") }
                if (isPortrait) { Spacer(modifier = Modifier.height(4.dp)) }
                Text(text = "Nuevo Juego")
            }
        }

        // Opción: Dificultad
        Button(onClick = { expanded = !expanded }) {
            Icon(imageVector = Icons.Default.Settings, contentDescription = "Dificultad")
            Spacer(modifier = Modifier.width(8.dp))
            Text(difficulty)
        }

        ExitButton(activity = activity, isPortrait = isPortrait)
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


    Spacer(modifier = Modifier.height(16.dp))

     //   ButtonWithDialog()

}



@Composable
fun ExitButton(activity: Activity?, isPortrait: Boolean) {
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
            if(isPortrait) { Icon(imageVector = Icons.Default.ExitToApp, contentDescription = "Salir") }
            if(isPortrait) { Spacer(modifier = Modifier.height(4.dp)) }
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
        modifier = Modifier.padding(4.dp).width(200.dp).height(60.dp) ,
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