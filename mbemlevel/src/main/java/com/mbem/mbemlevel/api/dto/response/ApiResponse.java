package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.util.List;
/**
 * Wrapper universel pour toutes les réponses HTTP MbemNova.
 * success=true → data présente · success=false → error présente
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
    boolean success, String message, T data, ErrorDetail error, LocalDateTime timestamp
) {
    public static <T> ApiResponse<T> ok(T data, String msg) {
        return new ApiResponse<>(true, msg, data, null, LocalDateTime.now()); }
    public static <T> ApiResponse<T> ok(T data) { return ok(data, "OK"); }
    public static <T> ApiResponse<T> ok(String msg) {
        return new ApiResponse<>(true, msg, null, null, LocalDateTime.now()); }
    public static <T> ApiResponse<T> err(String msg, String code) {
        return new ApiResponse<>(false, msg, null, new ErrorDetail(code, null), LocalDateTime.now()); }
    public static <T> ApiResponse<T> validation(String msg, List<String> details) {
        return new ApiResponse<>(false, msg, null, new ErrorDetail("VALIDATION_ERROR", details), LocalDateTime.now()); }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record ErrorDetail(String code, List<String> details) {}
}
