package com.mbem.mbemlevel.api.config;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
/** Compression GZIP activée dans application.yaml. Config MVC supplémentaire ici. */
@Configuration
@EnableWebMvc
public class WebConfig implements WebMvcConfigurer { }
