package com.mbem.mbemlevel.api.aspect;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.*;
import org.springframework.stereotype.Component;
/** Alerte si un use case dépasse 500ms (détecte les requêtes N+1, locks BDD). */
@Aspect @Component @Slf4j
public class PerformanceAspect {
    @Around("execution(* com.mbem.mbemlevel.application.usecase.*.*(..))")
    public Object measure(ProceedingJoinPoint pjp) throws Throwable {
        long t0 = System.currentTimeMillis();
        Object r = pjp.proceed();
        long ms = System.currentTimeMillis() - t0;
        if (ms > 500) log.warn("[PERF] {} — {}ms (seuil 500ms dépassé)", pjp.getSignature().toShortString(), ms);
        return r;
    }
}
