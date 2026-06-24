package com.mbem.mbemlevel.api.aspect;
import com.mbem.mbemlevel.infrastructure.audit.AuditLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.*;
import org.springframework.stereotype.Component;
import java.util.Map;
/**
 * Aspect AOP — trace automatiquement les actions sensibles (paiement, rôle, suspension).
 * Utilisé en complément des appels manuels dans les use cases.
 */
@Aspect @Component @RequiredArgsConstructor @Slf4j
public class AuditTrailAspect {
    private final AuditLogService auditService;

    @Around("@annotation(com.mbem.mbemlevel.api.aspect.Auditable)")
    public Object audit(ProceedingJoinPoint pjp) throws Throwable {
        String action = pjp.getSignature().getName().toUpperCase();
        try {
            Object result = pjp.proceed();
            log.debug("[AUDIT] {} OK", action);
            return result;
        } catch (Exception e) {
            auditService.echec(null, null, action + "_FAILURE", null, null,
                Map.of("error", e.getMessage()));
            throw e;
        }
    }
}
