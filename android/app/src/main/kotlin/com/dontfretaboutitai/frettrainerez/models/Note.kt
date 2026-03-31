package com.dontfretaboutitai.frettrainerez.models

enum class Note(val value: Int) {
    C(0), Cs(1), D(2), Ds(3), E(4), F(5), Fs(6), G(7), Gs(8), A(9), As(10), B(11);

    val sharpName: String get() = when (this) {
        C -> "C"; Cs -> "C#"; D -> "D"; Ds -> "D#"; E -> "E"; F -> "F"
        Fs -> "F#"; G -> "G"; Gs -> "G#"; A -> "A"; As -> "A#"; B -> "B"
    }

    val flatName: String get() = when (this) {
        C -> "C"; Cs -> "Db"; D -> "D"; Ds -> "Eb"; E -> "E"; F -> "F"
        Fs -> "Gb"; G -> "G"; Gs -> "Ab"; A -> "A"; As -> "Bb"; B -> "B"
    }

    fun displayName(useFlats: Boolean = false) = if (useFlats) flatName else sharpName

    fun advanced(by: Int): Note {
        val raw = ((value + by % 12) + 12) % 12
        return entries[raw]
    }

    companion object {
        val allCases: List<Note> get() = entries.toList()
    }
}
