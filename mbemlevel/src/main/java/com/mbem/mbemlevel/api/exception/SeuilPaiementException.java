package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class SeuilPaiementException extends MbemNovaException {
    public SeuilPaiementException() { super("Paiement requis pour continuer.", HttpStatus.PAYMENT_REQUIRED, "PAYMENT_REQUIRED"); }
    public SeuilPaiementException(String detail) { super(detail, HttpStatus.PAYMENT_REQUIRED, "PAYMENT_REQUIRED"); }
}
