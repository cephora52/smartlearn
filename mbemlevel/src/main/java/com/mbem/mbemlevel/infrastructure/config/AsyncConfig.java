package com.mbem.mbemlevel.infrastructure.config;

import org.springframework.aop.interceptor.AsyncUncaughtExceptionHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.*;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import java.util.concurrent.Executor;

/**
 * Configuration des thread pools asynchrones.
 *
 * Pools séparés pour éviter qu'une tâche lente (PDF) bloque les emails.
 *
 *   emailExecutor    → 10 threads  — envoi rapide, I/O externe SMTP
 *   whatsAppExecutor → 5 threads   — API Meta Business (lente parfois)
 *   pdfExecutor      → 4 threads   — CPU-intensif (iText génère le PDF)
 *   storageExecutor  → 6 threads   — upload MinIO (I/O réseau)
 *   defaultExecutor  → 8 threads   — tout le reste (@Async sans nom)
 *
 * Avec Virtual Threads activés, ces pools sont quasi-illimités côté OS.
 * On garde quand même des limites applicatives pour contrôler la charge.
 */
@Configuration
@EnableAsync
@EnableScheduling
public class AsyncConfig implements AsyncConfigurer {

    /** Pool dédié aux emails — SMTP Brevo/SendGrid */
    @Bean(name = "emailExecutor")
    public Executor emailExecutor() {
        return buildPool("EmailPool", 5, 10, 100);
    }

    /** Pool dédié WhatsApp Business API — peut être lente */
    @Bean(name = "whatsAppExecutor")
    public Executor whatsAppExecutor() {
        return buildPool("WhatsAppPool", 3, 5, 50);
    }

    /** Pool dédié génération PDF — iText est CPU-intensif */
    @Bean(name = "pdfExecutor")
    public Executor pdfExecutor() {
        return buildPool("PDFPool", 2, 4, 20);
    }

    /** Pool dédié upload MinIO — I/O réseau */
    @Bean(name = "storageExecutor")
    public Executor storageExecutor() {
        return buildPool("StoragePool", 4, 8, 50);
    }

    /** Pool par défaut pour @Async sans nom explicite */
    @Override
    public Executor getAsyncExecutor() {
        return buildPool("AsyncDefault", 4, 8, 200);
    }

    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return (ex, method, params) ->
            org.slf4j.LoggerFactory.getLogger(AsyncConfig.class)
                .error("[ASYNC] Exception non catchée dans {} : {}", method.getName(), ex.getMessage(), ex);
    }

    private ThreadPoolTaskExecutor buildPool(String name, int core, int max, int queue) {
        ThreadPoolTaskExecutor ex = new ThreadPoolTaskExecutor();
        ex.setCorePoolSize(core);
        ex.setMaxPoolSize(max);
        ex.setQueueCapacity(queue);
        ex.setThreadNamePrefix(name + "-");
        ex.setWaitForTasksToCompleteOnShutdown(true);
        ex.setAwaitTerminationSeconds(30);
        ex.initialize();
        return ex;
    }
}
