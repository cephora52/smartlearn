package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.NullValuePropertyMappingStrategy;
import org.mapstruct.ReportingPolicy;

import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.shared.Money;
import com.mbem.mbemlevel.infrastructure.persistence.entity.PaiementJpaEntity;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface PaiementJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Paiement toDomain(PaiementJpaEntity entity);

    PaiementJpaEntity toEntity(Paiement domain);
    
    // Mêmes méthodes de conversion
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
            return money.getAmount().setScale(0, java.math.RoundingMode.HALF_UP).longValue();
        }
    }
}
