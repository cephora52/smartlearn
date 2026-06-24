package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class TokenExpireException extends MbemNovaException {
    public TokenExpireException() { super("Token expiré. Reconnectez-vous.", HttpStatus.UNAUTHORIZED, "TOKEN_EXPIRED"); }
    public TokenExpireException(String detail) { super(detail, HttpStatus.UNAUTHORIZED, "TOKEN_EXPIRED"); }
}
