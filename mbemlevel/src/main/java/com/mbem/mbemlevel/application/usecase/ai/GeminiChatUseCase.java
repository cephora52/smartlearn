package com.mbem.mbemlevel.application.usecase.ai;

import com.mbem.mbemlevel.application.port.out.GeminiPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class GeminiChatUseCase {
    private final GeminiPort geminiPort;

    public String executer(String prompt) {
        return geminiPort.generateResponse(prompt);
    }
}
