package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class RateLimitException extends MbemNovaException {
    public RateLimitException() { super("Trop de requêtes.", HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMIT_EXCEEDED"); }
    public RateLimitException(String detail) { super(detail, HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMIT_EXCEEDED"); }
}
