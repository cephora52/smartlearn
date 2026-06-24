package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class CompteSuspenduException extends MbemNovaException {
    public CompteSuspenduException() { super("Compte suspendu. Contactez MbemNova.", HttpStatus.FORBIDDEN, "ACCOUNT_SUSPENDED"); }
    public CompteSuspenduException(String detail) { super(detail, HttpStatus.FORBIDDEN, "ACCOUNT_SUSPENDED"); }
}
