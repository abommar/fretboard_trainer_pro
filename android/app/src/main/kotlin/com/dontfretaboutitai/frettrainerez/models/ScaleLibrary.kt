package com.dontfretaboutitai.frettrainerez.models

enum class ScaleType(val displayName: String) {
    PENTATONIC_MINOR("Pentatonic Minor"),
    PENTATONIC_MAJOR("Pentatonic Major"),
    BLUES("Blues"),
    MAJOR("Major"),
    NATURAL_MINOR("Natural Minor"),
    DORIAN("Dorian"),
    MIXOLYDIAN("Mixolydian"),
    HARMONIC_MINOR("Harmonic Minor"),
    PHRYGIAN("Phrygian"),
    LYDIAN("Lydian");

    val intervals: List<Int> get() = when (this) {
        MAJOR           -> listOf(0, 2, 4, 5, 7, 9, 11)
        NATURAL_MINOR   -> listOf(0, 2, 3, 5, 7, 8, 10)
        PENTATONIC_MAJOR -> listOf(0, 2, 4, 7, 9)
        PENTATONIC_MINOR -> listOf(0, 3, 5, 7, 10)
        BLUES           -> listOf(0, 3, 5, 6, 7, 10)
        DORIAN          -> listOf(0, 2, 3, 5, 7, 9, 10)
        MIXOLYDIAN      -> listOf(0, 2, 4, 5, 7, 9, 10)
        HARMONIC_MINOR  -> listOf(0, 2, 3, 5, 7, 8, 11)
        PHRYGIAN        -> listOf(0, 1, 3, 5, 7, 8, 10)
        LYDIAN          -> listOf(0, 2, 4, 6, 7, 9, 11)
    }

    val flavor: String get() = when (this) {
        PENTATONIC_MINOR -> "Rock & blues staple"
        PENTATONIC_MAJOR -> "Country & folk"
        BLUES            -> "Soulful & gritty"
        MAJOR            -> "Happy & bright"
        NATURAL_MINOR    -> "Dark & moody"
        DORIAN           -> "Jazz & funk"
        MIXOLYDIAN       -> "Bluesy major"
        HARMONIC_MINOR   -> "Classical & exotic"
        PHRYGIAN         -> "Spanish & metal"
        LYDIAN           -> "Dreamy & ethereal"
    }

    fun notes(root: Note): List<Note> = intervals.map { root.advanced(it) }
}
