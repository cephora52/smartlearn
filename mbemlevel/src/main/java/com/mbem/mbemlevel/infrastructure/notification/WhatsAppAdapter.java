package com.mbem.mbemlevel.infrastructure.notification;
import com.mbem.mbemlevel.application.port.out.WhatsAppPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import java.util.Map;
/**
 * Adaptateur WhatsApp Business (Meta Graph API).
 * Token configuré via ENV VAR WHATSAPP_TOKEN.
 * En dev : si token absent, le message est seulement loggé.
 */
@Component @Slf4j
public class WhatsAppAdapter implements WhatsAppPort {
    @Value("${mbemnova.whatsapp.api-url:https://graph.facebook.com/v21.0}") private String apiUrl;
    @Value("${mbemnova.whatsapp.token:}") private String token;
    @Value("${mbemnova.whatsapp.phone-number-id:}") private String phoneNumberId;
    @Value("${mbemnova.whatsapp.enabled:false}") private boolean enabled;

    @Override
    public void envoyerMessage(String telephone, String message) {
        if (!enabled || token.isBlank()) {
            log.debug("[WHATSAPP-MOCK] To: {} | {}", telephone, message); return;
        }
        try {
            new RestTemplate().postForObject(
                apiUrl + "/" + phoneNumberId + "/messages",
                Map.of("messaging_product","whatsapp","to",telephone,
                       "type","text","text",Map.of("body",message)),
                String.class);
        } catch (Exception e) {
            log.error("[WHATSAPP] Erreur envoi vers {}: {}", telephone, e.getMessage());
        }
    }
    @Override
    public void envoyerTemplate(String telephone, String templateName, String... params) {
        log.debug("[WHATSAPP] Template {} vers {}", templateName, telephone);
        // Templates WhatsApp pré-approuvés par Meta — implémentation Phase 2
    }
}
