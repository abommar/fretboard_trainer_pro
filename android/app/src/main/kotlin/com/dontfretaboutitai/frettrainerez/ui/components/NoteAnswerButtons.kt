package com.dontfretaboutitai.frettrainerez.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dontfretaboutitai.frettrainerez.game.AnswerState
import com.dontfretaboutitai.frettrainerez.models.Note
import com.dontfretaboutitai.frettrainerez.ui.theme.CardBg
import com.dontfretaboutitai.frettrainerez.ui.theme.CorrectGreen
import com.dontfretaboutitai.frettrainerez.ui.theme.NoteButtonBg
import com.dontfretaboutitai.frettrainerez.ui.theme.TextMuted
import com.dontfretaboutitai.frettrainerez.ui.theme.TextPrimary
import com.dontfretaboutitai.frettrainerez.ui.theme.WrongRed

@Composable
fun NoteAnswerButtons(
    answerState: AnswerState,
    correctNote: Note,
    useFlats: Boolean = false,
    onAnswer: (Note) -> Unit,
) {
    LazyVerticalGrid(
        columns               = GridCells.Fixed(4),
        modifier              = Modifier
            .fillMaxWidth()
            .height(130.dp)
            .padding(horizontal = 12.dp),
        contentPadding        = PaddingValues(vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalArrangement   = Arrangement.spacedBy(5.dp),
        userScrollEnabled     = false,
    ) {
        items(Note.entries) { note ->
            // Determine state for this button
            val (bgColor, textColor, isActive) = when (answerState) {
                is AnswerState.Correct -> when (note) {
                    answerState.tapped -> Triple(CorrectGreen, TextPrimary, true)
                    else               -> Triple(NoteButtonBg, TextMuted, false)
                }
                is AnswerState.Wrong -> when (note) {
                    answerState.tapped  -> Triple(WrongRed,     TextPrimary, true)
                    answerState.correct -> Triple(CorrectGreen, TextPrimary, true)
                    else                -> Triple(NoteButtonBg, TextMuted,   false)
                }
                AnswerState.Idle -> Triple(NoteButtonBg, TextPrimary, false)
            }

            // Subtle hue tint per note (chromatic color coding, same as iOS)
            val noteHue = note.value / 12f
            val tintColor = Color.hsv(noteHue * 360f, 0.7f, 0.9f)
            val finalBg = if (answerState == AnswerState.Idle) {
                lerp(NoteButtonBg, tintColor, 0.10f)  // subtle 10% tint
            } else bgColor

            Button(
                onClick  = { if (answerState == AnswerState.Idle) onAnswer(note) },
                modifier = Modifier.height(38.dp),
                colors   = ButtonDefaults.buttonColors(
                    containerColor         = finalBg,
                    disabledContainerColor = finalBg.copy(alpha = 0.5f),
                ),
                shape           = RoundedCornerShape(8.dp),
                contentPadding  = PaddingValues(0.dp),
                elevation       = ButtonDefaults.buttonElevation(
                    defaultElevation = if (isActive) 0.dp else 2.dp
                ),
            ) {
                Text(
                    text       = note.displayName(useFlats),
                    fontSize   = 13.sp,
                    fontWeight = if (isActive) FontWeight.Black else FontWeight.SemiBold,
                    color      = textColor,
                )
            }
        }
    }
}
