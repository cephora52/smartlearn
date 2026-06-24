package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class EmailDejaUtiliseException extends MbemNovaException {
    public EmailDejaUtiliseException() { super("Cet email est déjà utilisé.", HttpStatus.CONFLICT, "EMAIL_ALREADY_EXISTS"); }
    public EmailDejaUtiliseException(String detail) { super(detail, HttpStatus.CONFLICT, "EMAIL_ALREADY_EXISTS"); }
}
