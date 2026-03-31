package com.dontfretaboutitai.frettrainerez.models

data class ChordVoicing(
    val root: Note,
    val type: ChordType,
    val frets: List<Int?>,   // 6 values: null=muted, 0=open, 1+=fret number; index 0=low E
    val baseFret: Int = 1
) {
    val name: String get() = "${root.sharpName}${type.suffix}"
    val chordTones: List<Note> get() = type.intervals.map { root.advanced(it) }
}

enum class ChordType(val displayName: String) {
    MAJOR("Major"),
    MINOR("Minor"),
    DOMINANT7("7"),
    MAJOR7("maj7"),
    MINOR7("m7"),
    SUS2("sus2"),
    SUS4("sus4");

    val intervals: List<Int> get() = when (this) {
        MAJOR     -> listOf(0, 4, 7)
        MINOR     -> listOf(0, 3, 7)
        DOMINANT7 -> listOf(0, 4, 7, 10)
        MAJOR7    -> listOf(0, 4, 7, 11)
        MINOR7    -> listOf(0, 3, 7, 10)
        SUS2      -> listOf(0, 2, 7)
        SUS4      -> listOf(0, 5, 7)
    }

    val suffix: String get() = when (this) {
        MAJOR     -> ""; MINOR -> "m"; DOMINANT7 -> "7"
        MAJOR7    -> "maj7"; MINOR7 -> "m7"; SUS2 -> "sus2"; SUS4 -> "sus4"
    }

    val degreeSymbols: List<String> get() = when (this) {
        MAJOR     -> listOf("1", "3", "5")
        MINOR     -> listOf("1", "b3", "5")
        DOMINANT7 -> listOf("1", "3", "5", "b7")
        MAJOR7    -> listOf("1", "3", "5", "7")
        MINOR7    -> listOf("1", "b3", "5", "b7")
        SUS2      -> listOf("1", "2", "5")
        SUS4      -> listOf("1", "4", "5")
    }

    val degreeNames: List<String> get() = when (this) {
        MAJOR     -> listOf("Root", "Major 3rd", "Perfect 5th")
        MINOR     -> listOf("Root", "Minor 3rd", "Perfect 5th")
        DOMINANT7 -> listOf("Root", "Major 3rd", "Perfect 5th", "Minor 7th")
        MAJOR7    -> listOf("Root", "Major 3rd", "Perfect 5th", "Major 7th")
        MINOR7    -> listOf("Root", "Minor 3rd", "Perfect 5th", "Minor 7th")
        SUS2      -> listOf("Root", "Major 2nd", "Perfect 5th")
        SUS4      -> listOf("Root", "Perfect 4th", "Perfect 5th")
    }

    val mood: String get() = when (this) {
        MAJOR     -> "Bright & stable — the foundation of harmony"
        MINOR     -> "Dark & emotive — melancholic character"
        DOMINANT7 -> "Bluesy & tense — wants to resolve to the tonic"
        MAJOR7    -> "Dreamy & lush — jazzy, sophisticated sound"
        MINOR7    -> "Mellow & soulful — common in jazz, R&B, and soul"
        SUS2      -> "Open & airy — neither major nor minor, floats freely"
        SUS4      -> "Suspended & anticipating — naturally resolves to major"
    }
}

private fun v(root: Note, type: ChordType, vararg frets: Int?, baseFret: Int = 1) =
    ChordVoicing(root, type, frets.toList(), baseFret)

object ChordLibrary {
    val all: List<ChordVoicing> = listOf(
        // MARK: Major
        v(Note.C,  ChordType.MAJOR, null,3,2,0,1,0),
        v(Note.D,  ChordType.MAJOR, null,null,0,2,3,2),
        v(Note.E,  ChordType.MAJOR, 0,2,2,1,0,0),
        v(Note.F,  ChordType.MAJOR, 1,3,3,2,1,1),
        v(Note.G,  ChordType.MAJOR, 3,2,0,0,0,3),
        v(Note.A,  ChordType.MAJOR, null,0,2,2,2,0),
        v(Note.B,  ChordType.MAJOR, null,2,4,4,4,2),
        v(Note.Fs, ChordType.MAJOR, 2,4,4,3,2,2, baseFret=2),
        v(Note.Gs, ChordType.MAJOR, 4,6,6,5,4,4, baseFret=4),
        v(Note.As, ChordType.MAJOR, null,1,3,3,3,1),
        v(Note.Cs, ChordType.MAJOR, null,4,6,6,6,4, baseFret=4),
        v(Note.Ds, ChordType.MAJOR, null,6,8,8,8,6, baseFret=6),

        // MARK: Minor
        v(Note.C,  ChordType.MINOR, null,3,5,5,4,3, baseFret=3),
        v(Note.D,  ChordType.MINOR, null,null,0,2,3,1),
        v(Note.E,  ChordType.MINOR, 0,2,2,0,0,0),
        v(Note.F,  ChordType.MINOR, 1,3,3,1,1,1),
        v(Note.G,  ChordType.MINOR, 3,5,5,3,3,3, baseFret=3),
        v(Note.A,  ChordType.MINOR, null,0,2,2,1,0),
        v(Note.B,  ChordType.MINOR, null,2,4,4,3,2),
        v(Note.Fs, ChordType.MINOR, 2,4,4,2,2,2, baseFret=2),
        v(Note.Gs, ChordType.MINOR, 4,6,6,4,4,4, baseFret=4),
        v(Note.As, ChordType.MINOR, null,1,3,3,2,1),
        v(Note.Cs, ChordType.MINOR, null,4,6,6,5,4, baseFret=4),
        v(Note.Ds, ChordType.MINOR, null,6,8,8,7,6, baseFret=6),

        // MARK: Dominant 7
        v(Note.C,  ChordType.DOMINANT7, null,3,2,3,1,0),
        v(Note.D,  ChordType.DOMINANT7, null,null,0,2,1,2),
        v(Note.E,  ChordType.DOMINANT7, 0,2,0,1,0,0),
        v(Note.G,  ChordType.DOMINANT7, 3,2,0,0,0,1),
        v(Note.A,  ChordType.DOMINANT7, null,0,2,0,2,0),
        v(Note.B,  ChordType.DOMINANT7, null,2,1,2,0,2),
        v(Note.F,  ChordType.DOMINANT7, 1,3,1,2,1,1),
        v(Note.Fs, ChordType.DOMINANT7, 2,4,2,3,2,2, baseFret=2),
        v(Note.Gs, ChordType.DOMINANT7, 4,6,4,5,4,4, baseFret=4),
        v(Note.As, ChordType.DOMINANT7, null,1,3,1,3,1),
        v(Note.Cs, ChordType.DOMINANT7, null,4,6,4,6,4, baseFret=4),
        v(Note.Ds, ChordType.DOMINANT7, null,6,8,6,8,6, baseFret=6),

        // MARK: Major 7
        v(Note.C,  ChordType.MAJOR7, null,3,2,0,0,0),
        v(Note.D,  ChordType.MAJOR7, null,null,0,2,2,2),
        v(Note.E,  ChordType.MAJOR7, 0,2,1,1,0,0),
        v(Note.G,  ChordType.MAJOR7, 3,2,0,0,0,2),
        v(Note.A,  ChordType.MAJOR7, null,0,2,1,2,0),
        v(Note.F,  ChordType.MAJOR7, 1,3,2,2,1,1),
        v(Note.B,  ChordType.MAJOR7, null,2,4,3,4,2, baseFret=2),
        v(Note.Fs, ChordType.MAJOR7, 2,4,3,3,2,2, baseFret=2),
        v(Note.Gs, ChordType.MAJOR7, 4,6,5,5,4,4, baseFret=4),
        v(Note.As, ChordType.MAJOR7, null,1,3,2,3,1),
        v(Note.Cs, ChordType.MAJOR7, null,4,6,5,6,4, baseFret=4),
        v(Note.Ds, ChordType.MAJOR7, null,6,8,7,8,6, baseFret=6),

        // MARK: Minor 7
        v(Note.A,  ChordType.MINOR7, null,0,2,0,1,0),
        v(Note.D,  ChordType.MINOR7, null,null,0,2,1,1),
        v(Note.E,  ChordType.MINOR7, 0,2,2,0,3,0),
        v(Note.G,  ChordType.MINOR7, 3,5,3,3,3,3, baseFret=3),
        v(Note.C,  ChordType.MINOR7, null,3,5,3,4,3, baseFret=3),
        v(Note.F,  ChordType.MINOR7, 1,3,1,1,1,1),
        v(Note.B,  ChordType.MINOR7, null,2,4,2,3,2, baseFret=2),
        v(Note.Fs, ChordType.MINOR7, 2,4,2,2,2,2, baseFret=2),
        v(Note.Gs, ChordType.MINOR7, 4,6,4,4,4,4, baseFret=4),
        v(Note.As, ChordType.MINOR7, null,1,3,1,2,1),
        v(Note.Cs, ChordType.MINOR7, null,4,6,4,5,4, baseFret=4),
        v(Note.Ds, ChordType.MINOR7, null,6,8,6,7,6, baseFret=6),

        // MARK: Sus2
        v(Note.D,  ChordType.SUS2, null,null,0,2,3,0),
        v(Note.A,  ChordType.SUS2, null,0,2,2,0,0),
        v(Note.E,  ChordType.SUS2, 0,2,4,4,0,0),
        v(Note.G,  ChordType.SUS2, 3,0,0,0,3,3),

        // MARK: Sus4
        v(Note.D,  ChordType.SUS4, null,null,0,2,3,3),
        v(Note.A,  ChordType.SUS4, null,0,2,2,3,0),
        v(Note.E,  ChordType.SUS4, 0,2,2,2,0,0),
        v(Note.G,  ChordType.SUS4, 3,3,0,0,1,3),
    )

    fun voicings(root: Note, type: ChordType) = all.filter { it.root == root && it.type == type }
}
