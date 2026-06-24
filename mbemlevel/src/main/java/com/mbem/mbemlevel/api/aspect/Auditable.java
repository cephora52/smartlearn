package com.mbem.mbemlevel.api.aspect;
import java.lang.annotation.*;
/** Marque une méthode à tracer automatiquement dans l'audit log. */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Auditable {}
