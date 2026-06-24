package com.mbem.mbemlevel.application.port.out;
/** Port sortant — envoi de messages WhatsApp Business (Meta API). */
public interface WhatsAppPort {
    void envoyerMessage(String telephone, String message);
    void envoyerTemplate(String telephone, String templateName, String... params);
}
