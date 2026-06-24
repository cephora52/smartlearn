package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.paiement.Moratoire;
import com.mbem.mbemlevel.infrastructure.persistence.entity.MoratoireJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface MoratoireJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Moratoire toDomain(MoratoireJpaEntity entity);

    MoratoireJpaEntity toEntity(Moratoire domain);
}
