package com.dontfretaboutitai.frettrainerez.models

import androidx.compose.ui.graphics.Color

enum class FretboardStyle(val displayName: String) {
    ROSEWOOD("Rosewood"),
    MAPLE("Maple"),
    EBONY("Ebony"),
    WALNUT("Walnut"),
    MIDNIGHT("Midnight");

    val descriptor: String get() = when (this) {
        ROSEWOOD -> "Classic dark rosewood"
        MAPLE    -> "Bright honey maple"
        EBONY    -> "Jet black with gold frets"
        WALNUT   -> "Warm medium brown"
        MIDNIGHT -> "Deep midnight blue"
    }

    val boardColors: List<Color> get() = when (this) {
        ROSEWOOD -> listOf(Color(0xFF4A3525), Color(0xFF3D2B1F), Color(0xFF2E1F14))
        MAPLE    -> listOf(Color(0xFFC8A87A), Color(0xFFB89358), Color(0xFFA07840))
        EBONY    -> listOf(Color(0xFF1C1C1C), Color(0xFF141414), Color(0xFF0C0C0C))
        WALNUT   -> listOf(Color(0xFF5C3D1E), Color(0xFF4A2E14), Color(0xFF361E0A))
        MIDNIGHT -> listOf(Color(0xFF1A1A3E), Color(0xFF141430), Color(0xFF0D0D20))
    }

    val nutColor: Color get() = when (this) {
        ROSEWOOD -> Color(0xFFE8D5A3)
        MAPLE    -> Color(0xFFF5ECD0)
        EBONY    -> Color(0xFFD0C8B0)
        WALNUT   -> Color(0xFFDFC898)
        MIDNIGHT -> Color(0xFF8888CC)
    }

    val fretColors: List<Color> get() = when (this) {
        ROSEWOOD -> listOf(Color(0xFFA0A0A0), Color(0xFFD0D0D0), Color(0xFFA0A0A0))
        MAPLE    -> listOf(Color(0xFFC0B890), Color(0xFFE8D8B0), Color(0xFFC0B890))
        EBONY    -> listOf(Color(0xFFA08830), Color(0xFFD4B840), Color(0xFFA08830))
        WALNUT   -> listOf(Color(0xFFA09060), Color(0xFFC8B070), Color(0xFFA09060))
        MIDNIGHT -> listOf(Color(0xFF6060A8), Color(0xFF9090D0), Color(0xFF6060A8))
    }

    val stringColors: List<Color> get() = when (this) {
        ROSEWOOD -> listOf(Color(0xFFB8B8B8), Color(0xFFE8E8E8), Color(0xFFB8B8B8))
        MAPLE    -> listOf(Color(0xFFC8C0A0), Color(0xFFF0E8C0), Color(0xFFC8C0A0))
        EBONY    -> listOf(Color(0xFFA8A8A8), Color(0xFFD8D8D8), Color(0xFFA8A8A8))
        WALNUT   -> listOf(Color(0xFFB8A878), Color(0xFFE0D0A0), Color(0xFFB8A878))
        MIDNIGHT -> listOf(Color(0xFF8080C0), Color(0xFFC0C0F0), Color(0xFF8080C0))
    }

    val pearlBase: Color get() = Color(0xFFEDE8E0)
}
