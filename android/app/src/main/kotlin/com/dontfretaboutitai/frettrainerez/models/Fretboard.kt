package com.dontfretaboutitai.frettrainerez.models

data class FretPosition(val string: Int, val fret: Int)

class Fretboard(
    val tuning: GuitarTuning = GuitarTuning.standard,
    val fretCount: Int = 22
) {
    fun note(string: Int, fret: Int): Note = tuning.strings[string].advanced(fret)

    fun allPositionsFor(note: Note): List<FretPosition> {
        val positions = mutableListOf<FretPosition>()
        for (s in 0 until tuning.stringCount) {
            for (f in 0..fretCount) {
                if (this.note(s, f) == note) positions.add(FretPosition(s, f))
            }
        }
        return positions
    }
}
