package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class RessourceIntrouvableException extends MbemNovaException {
    public RessourceIntrouvableException() { super("Ressource introuvable.", HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND"); }
    public RessourceIntrouvableException(String detail) { super(detail, HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND"); }
}
