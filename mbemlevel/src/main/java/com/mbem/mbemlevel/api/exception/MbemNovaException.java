package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class MbemNovaException extends RuntimeException {
    private final HttpStatus status;
    private final String     code;
    public MbemNovaException(String msg, HttpStatus status, String code) {
        super(msg); this.status = status; this.code = code;
    }
    public HttpStatus getStatus() { return status; }
    public String     getCode()   { return code; }
}
