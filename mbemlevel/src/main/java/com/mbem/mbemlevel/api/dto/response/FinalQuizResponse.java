package com.mbem.mbemlevel.api.dto.response;

import java.util.List;

public record FinalQuizResponse(List<QuestionDto> questions) {
    public record QuestionDto(
        String question,
        List<String> options,
        int correctAnswer,
        String explanation
    ) {}
}
