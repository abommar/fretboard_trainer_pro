package com.dontfretaboutitai.frettrainerez.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.game.AnswerState
import com.dontfretaboutitai.frettrainerez.models.Note
import com.dontfretaboutitai.frettrainerez.ui.theme.AccentRed
import com.dontfretaboutitai.frettrainerez.ui.theme.CorrectGreen
import com.dontfretaboutitai.frettrainerez.ui.theme.NoteButtonBg
import com.dontfretaboutitai.frettrainerez.ui.theme.WrongRed

@Composable
fun NoteAnswerButtons(
    answerState: AnswerState,
    correctNote: Note,
    useFlats: Boolean = false,
    onAnswer: (Note) -> Unit,
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(4),
        modifier = Modifier.fillMaxWidth().height(120.dp),
        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalArrangement   = Arrangement.spacedBy(4.dp),
    ) {
        items(Note.entries) { note ->
            val bgColor = when (answerState) {
                is AnswerState.Correct -> when (note) {
                    answerState.tapped -> CorrectGreen
                    else               -> NoteButtonBg
                }
                is AnswerState.Wrong -> when (note) {
                    answerState.tapped  -> WrongRed
                    answerState.correct -> CorrectGreen
                    else                -> NoteButtonBg
                }
                AnswerState.Idle -> NoteButtonBg
            }

            Button(
                onClick = { if (answerState == AnswerState.Idle) onAnswer(note) },
                colors = ButtonDefaults.buttonColors(containerColor = bgColor),
                modifier = Modifier.height(36.dp),
                contentPadding = PaddingValues(0.dp),
            ) {
                Text(
                    text = note.displayName(useFlats),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                )
            }
        }
    }
}
