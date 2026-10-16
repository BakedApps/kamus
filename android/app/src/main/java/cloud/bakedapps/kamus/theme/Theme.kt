package cloud.bakedapps.kamus.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColorScheme = lightColorScheme(
    primary = KamusNavy,
    onPrimary = Color.White,
    primaryContainer = KamusCream,
    onPrimaryContainer = KamusDarkNavy,
    secondary = KamusAmber,
    onSecondary = Color.White,
    background = KamusBackgroundLight,
    surface = KamusSurfaceLight,
    onSurface = Color(0xFF1C1B1F),
    outline = KamusBorderLight
)

private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFF9EA8DB),
    onPrimary = KamusDarkNavy,
    primaryContainer = Color(0xFF283593),
    onPrimaryContainer = KamusCream,
    secondary = KamusAmber,
    onSecondary = Color.Black,
    background = Color(0xFF121212),
    surface = Color(0xFF1E1E1E),
    onSurface = Color(0xFFE0E0E0),
    outline = Color(0xFF2C2C2C)
)

@Composable
fun KamusTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                window.statusBarColor = colorScheme.background.toArgb()
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
