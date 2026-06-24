package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
public record InscrireSessionRequest(@NotNull UUID coursId) {}
