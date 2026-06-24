package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import org.springframework.boot.info.BuildProperties;
import org.springframework.context.annotation.Import;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.Map;
@RestController
@RequestMapping("/api/v1")
public class HealthController {
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> health() {
        return ResponseEntity.ok(ApiResponse.ok(
            Map.of("status","UP","timestamp", LocalDateTime.now().toString())));
    }
}
