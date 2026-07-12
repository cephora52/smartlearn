package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.TirageAuSortRepository;
import com.mbem.mbemlevel.domain.gamification.TirageAuSort;
import com.mbem.mbemlevel.infrastructure.persistence.entity.GagnantTirageJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.entity.TirageAuSortJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.GagnantTirageJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.TirageAuSortJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class TirageAuSortRepositoryAdapter implements TirageAuSortRepository {

    private final TirageAuSortJpaRepository  tirageJpaRepository;
    private final GagnantTirageJpaRepository gagnantJpaRepository;
    private final UtilisateurJpaRepository   utilisateurJpaRepository;

    private static final DateTimeFormatter MOIS_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM");

    @Override
    @Transactional
    public void sauvegarder(TirageAuSort tirage, UUID adminId) {
        UUID tirageId = tirage.getId() != null ? tirage.getId() : UUID.randomUUID();
        String moisStr = tirage.getMois().format(MOIS_FORMATTER);

        TirageAuSortJpaEntity tirageEntity = TirageAuSortJpaEntity.builder()
            .id(tirageId)
            .mois(moisStr)
            .nbParticipants(tirage.getNbParticipants())
            .formationPrix(tirage.getPrixDescription())
            .valeurPrix(45000L) // Valeur indicative par défaut (ex: prix d'une formation)
            .adminId(adminId)
            .effectueLe(LocalDateTime.now())
            .build();

        tirageJpaRepository.save(tirageEntity);

        if (tirage.getGagnantId() != null) {
            GagnantTirageJpaEntity gagnantEntity = GagnantTirageJpaEntity.builder()
                .id(UUID.randomUUID())
                .tirageId(tirageId)
                .apprenantId(tirage.getGagnantId())
                .rang(1) // Gagnant principal
                .lotDescription(tirage.getPrixDescription())
                .notifie(true)
                .build();

            gagnantJpaRepository.save(gagnantEntity);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<TirageAuSort> findLatest() {
        return tirageJpaRepository.findAll().stream()
            .max(Comparator.comparing(TirageAuSortJpaEntity::getEffectueLe))
            .map(entity -> {
                LocalDate mois = LocalDate.parse(entity.getMois() + "-01");
                
                UUID gagnantId = gagnantJpaRepository.findAll().stream()
                    .filter(g -> g.getTirageId().equals(entity.getId()) && g.getRang() == 1)
                    .map(GagnantTirageJpaEntity::getApprenantId)
                    .findFirst()
                    .orElse(null);

                return new TirageAuSort(
                    entity.getId(),
                    mois,
                    gagnantId,
                    entity.getNbParticipants(),
                    entity.getFormationPrix(),
                    entity.getCreatedAt(),
                    entity.getEffectueLe()
                );
            });
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<String> findGagnantPrenom(UUID tirageId) {
        return gagnantJpaRepository.findAll().stream()
            .filter(g -> g.getTirageId().equals(tirageId) && g.getRang() == 1)
            .findFirst()
            .flatMap(g -> utilisateurJpaRepository.findById(g.getApprenantId()))
            .map(u -> u.getPrenom());
    }
}
