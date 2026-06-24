package com.mbem.mbemlevel.api.dto.request;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
public record AssignerRoleRequest(
    @NotNull UUID utilisateurId,
    @NotNull Role nouveauRole
) {}
