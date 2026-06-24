package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.NullValuePropertyMappingStrategy;
import org.mapstruct.ReportingPolicy;

import com.mbem.mbemlevel.domain.paiement.Tranche;
import com.mbem.mbemlevel.domain.shared.Money;
import com.mbem.mbemlevel.infrastructure.persistence.entity.TrancheJpaEntity;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface TrancheJpaMapper {
    Tranche toDomain(TrancheJpaEntity entity);
    TrancheJpaEntity toEntity(Tranche domain);

    // MapStruct utilisera automatiquement ces méthodes
    default Money map(long value) {
        return Money.of(value);
    }
    
   default long map(Money money) {
    if (money == null || money.getAmount() == null) {
        return 0L;
    }
    try {
        return money.getAmount().longValueExact();
    } catch (ArithmeticException e) {
        // Arrondir si perte de précision
        return money.getAmount().setScale(0, java.math.RoundingMode.HALF_UP).longValue();
    }
}
}
