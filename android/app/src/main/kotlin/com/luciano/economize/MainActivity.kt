package com.lucianoribeiro.economize

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import androidx.core.view.WindowCompat

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // MÍNIMO: Apenas habilitar Edge-to-Edge
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }
}