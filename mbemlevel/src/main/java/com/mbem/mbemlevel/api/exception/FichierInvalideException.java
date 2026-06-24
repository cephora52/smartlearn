package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class FichierInvalideException extends MbemNovaException {
    public FichierInvalideException() { super("Fichier invalide.", HttpStatus.BAD_REQUEST, "INVALID_FILE"); }
    public FichierInvalideException(String detail) { super(detail, HttpStatus.BAD_REQUEST, "INVALID_FILE"); }
}
