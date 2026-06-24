package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record ResetPasswordRequest(@NotBlank @Email String email) {}
