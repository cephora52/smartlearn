package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "categories")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CategorieJpaEntity {
    @Id
    private UUID id;

    @Column(nullable = false, unique = true, length = 100)
    private String nom;

    @Column(length = 500)
    private String description;

    @Column(length = 100)
    private String icone;
}
