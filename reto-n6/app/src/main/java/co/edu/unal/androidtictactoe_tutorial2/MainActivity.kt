package co.edu.unal.androidtictactoe_tutorial2

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import co.edu.unal.androidtictactoe_tutorial2.ui.GameScreen
import co.edu.unal.androidtictactoe_tutorial2.ui.theme.UnscrambleTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import co.edu.unal.androidtictactoe_tutorial2.ui.GameViewModel
import android.content.Context

class MainActivity : ComponentActivity() {
    private var score = 0
    private val sharedPreferences by lazy {
        getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        // Cargar el estado desde SharedPreferences
        score = sharedPreferences.getInt("SCORE_KEY", 0)

        setContent {
            UnscrambleTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                ) {
                    GameScreen(GameViewModel(),this)
                }
            }
        }
    }

}


@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello $name!",
        modifier = modifier
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    UnscrambleTheme {
        Greeting("Android")
    }
}




