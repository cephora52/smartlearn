package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class AccesInterditException extends MbemNovaException {
    public AccesInterditException() { super("Accès refusé.", HttpStatus.FORBIDDEN, "ACCESS_DENIED"); }
    public AccesInterditException(String detail) { super(detail, HttpStatus.FORBIDDEN, "ACCESS_DENIED"); }
}
