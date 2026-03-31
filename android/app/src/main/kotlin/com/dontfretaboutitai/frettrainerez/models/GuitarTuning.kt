package com.dontfretaboutitai.frettrainerez.models

data class GuitarTuning(
    val id: String,
    val name: String,
    val strings: List<Note>,   // index 0 = lowest string
    val useFlats: Boolean = false
) {
    val stringCount: Int get() = strings.size

    companion object {
        val standard     = GuitarTuning("standard",     "Standard",        listOf(Note.E,  Note.A,  Note.D,  Note.G,  Note.B,  Note.E))
        val dropD        = GuitarTuning("dropD",        "Drop D",          listOf(Note.D,  Note.A,  Note.D,  Note.G,  Note.B,  Note.E))
        val openG        = GuitarTuning("openG",        "Open G",          listOf(Note.D,  Note.G,  Note.D,  Note.G,  Note.B,  Note.D))
        val openD        = GuitarTuning("openD",        "Open D",          listOf(Note.D,  Note.A,  Note.D,  Note.Fs, Note.A,  Note.D))
        val dadgad       = GuitarTuning("dadgad",       "DADGAD",          listOf(Note.D,  Note.A,  Note.D,  Note.G,  Note.A,  Note.D))
        val openE        = GuitarTuning("openE",        "Open E",          listOf(Note.E,  Note.B,  Note.E,  Note.Gs, Note.B,  Note.E))
        val openA        = GuitarTuning("openA",        "Open A",          listOf(Note.E,  Note.A,  Note.E,  Note.A,  Note.Cs, Note.E))
        val halfStepDown = GuitarTuning("halfStepDown", "Half Step Down",  listOf(Note.Ds, Note.Gs, Note.Cs, Note.Fs, Note.As, Note.Ds), useFlats = true)
        val fullStepDown = GuitarTuning("fullStepDown", "Full Step Down",  listOf(Note.D,  Note.G,  Note.C,  Note.F,  Note.A,  Note.D))
        val dropC        = GuitarTuning("dropC",        "Drop C",          listOf(Note.C,  Note.G,  Note.C,  Note.F,  Note.A,  Note.D))

        val all = listOf(standard, dropD, openG, openD, dadgad, openE, openA, halfStepDown, fullStepDown, dropC)
    }
}
