package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.session.Rendu;
import com.mbem.mbemlevel.infrastructure.persistence.entity.RenduJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface RenduJpaMapper {
    Rendu toDomain(RenduJpaEntity entity);
    RenduJpaEntity toEntity(Rendu domain);
}
