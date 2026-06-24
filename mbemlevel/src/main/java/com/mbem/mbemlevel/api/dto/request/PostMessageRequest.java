package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
import java.util.UUID;
public record PostMessageRequest(
    @NotBlank @Size(max=2000) String contenu,
    UUID parentId  // null = nouvelle question, non-null = réponse
) {}
