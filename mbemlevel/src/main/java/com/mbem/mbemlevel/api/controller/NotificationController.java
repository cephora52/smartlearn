package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.port.out.NotificationRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import java.util.stream.Collectors;
/**
 * API Notifications — cloche in-app.
 * GET   /api/v1/notifications      → toutes mes notifications
 * GET   /api/v1/notifications/unread → non lues
 * PATCH /api/v1/notifications/read-all → tout marquer lu
 */
@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name="Notification", description="Notifications in-app")
@RequiredArgsConstructor
public class NotificationController {
    private final NotificationRepository repo;

    @GetMapping
    @Operation(summary="Mes notifications")
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> mesNotifications(
            @AuthenticationPrincipal String userId) {
        List<NotificationResponse> list = repo.findByUtilisateur(UUID.fromString(userId))
            .stream().map(NotificationResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @GetMapping("/unread")
    @Operation(summary="Notifications non lues")
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> nonLues(
            @AuthenticationPrincipal String userId) {
        List<NotificationResponse> list = repo.findNonLues(UUID.fromString(userId))
            .stream().map(NotificationResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @PatchMapping("/read-all")
    @Operation(summary="Marquer toutes les notifications comme lues")
    public ResponseEntity<ApiResponse<Void>> toutMarquerLu(
            @AuthenticationPrincipal String userId) {
        repo.marquerToutesLues(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok("Notifications marquées lues."));
    }
}
