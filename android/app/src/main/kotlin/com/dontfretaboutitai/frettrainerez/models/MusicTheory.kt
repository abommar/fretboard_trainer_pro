package com.dontfretaboutitai.frettrainerez.models

enum class ChordFunction { TONIC, SUBDOMINANT, DOMINANT }

data class DiatonicChord(
    val numeral: String,
    val name: String,
    val chordFunction: ChordFunction
)

data class Progression(
    val name: String,
    val style: String,
    val indices: List<Int>
)

object MusicTheory {

    data class KeyInfo(
        val major: Note,
        val relative: Note,
        val sharpsOrFlats: Int
    )

    val circleOfFifths: List<KeyInfo> = listOf(
        KeyInfo(Note.C,  Note.A,  0),
        KeyInfo(Note.G,  Note.E,  1),
        KeyInfo(Note.D,  Note.B,  2),
        KeyInfo(Note.A,  Note.Fs, 3),
        KeyInfo(Note.E,  Note.Cs, 4),
        KeyInfo(Note.B,  Note.Gs, 5),
        KeyInfo(Note.Fs, Note.Ds, 6),
        KeyInfo(Note.Cs, Note.As, -5),
        KeyInfo(Note.Gs, Note.F,  -4),
        KeyInfo(Note.Ds, Note.C,  -3),
        KeyInfo(Note.As, Note.G,  -2),
        KeyInfo(Note.F,  Note.D,  -1),
    )

    fun diatonicChords(keyPosition: Int, useFlats: Boolean = false): List<DiatonicChord> {
        val k = keyPosition
        val cof = circleOfFifths
        val km1 = (k - 1 + 12) % 12
        val kp1 = (k + 1) % 12
        fun n(note: Note) = note.displayName(useFlats)
        return listOf(
            DiatonicChord("I",    n(cof[k].major),                         ChordFunction.TONIC),
            DiatonicChord("ii",   n(cof[km1].relative) + "m",              ChordFunction.SUBDOMINANT),
            DiatonicChord("iii",  n(cof[kp1].relative) + "m",              ChordFunction.TONIC),
            DiatonicChord("IV",   n(cof[km1].major),                        ChordFunction.SUBDOMINANT),
            DiatonicChord("V",    n(cof[kp1].major),                        ChordFunction.DOMINANT),
            DiatonicChord("vi",   n(cof[k].relative) + "m",                ChordFunction.TONIC),
            DiatonicChord("vii°", n(cof[k].major.advanced(11)) + "°",      ChordFunction.DOMINANT),
        )
    }

    fun diatonicCirclePositions(keyPosition: Int): Map<Int, ChordFunction> {
        val k = keyPosition
        val km1 = (k - 1 + 12) % 12
        val kp1 = (k + 1) % 12
        return mapOf(km1 to ChordFunction.SUBDOMINANT, k to ChordFunction.TONIC, kp1 to ChordFunction.DOMINANT)
    }

    val commonProgressions: List<Progression> = listOf(
        Progression("I–IV–V",    "Rock & Blues",  listOf(0, 3, 4)),
        Progression("I–V–vi–IV", "Pop",           listOf(0, 4, 5, 3)),
        Progression("I–vi–IV–V", "50s / Doo-wop", listOf(0, 5, 3, 4)),
        Progression("ii–V–I",    "Jazz",          listOf(1, 4, 0)),
    )

    fun enharmonicLabel(note: Note, position: Int): String = when (position) {
        7  -> "C\u266d/B"
        8  -> "A\u266d/G#"
        9  -> "E\u266d/D#"
        10 -> "B\u266d/A#"
        6  -> "F#/G\u266d"
        else -> note.sharpName
    }

    fun relativeLabel(note: Note, position: Int): String = when (position) {
        3  -> "F#m"; 4  -> "C#m"; 5  -> "G#m"; 6  -> "D#m"
        7  -> "Bbm"; 8  -> "Fm";  9  -> "Cm";  10 -> "Gm"; 11 -> "Dm"
        else -> "${note.sharpName}m"
    }

    fun accidentalLabel(sharpsOrFlats: Int): String {
        if (sharpsOrFlats == 0) return "0"
        val symbol = if (sharpsOrFlats > 0) "♯" else "♭"
        return "${kotlin.math.abs(sharpsOrFlats)}$symbol"
    }
}
