package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.session.Devoir;
import com.mbem.mbemlevel.infrastructure.persistence.entity.DevoirJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface DevoirJpaMapper {
    Devoir toDomain(DevoirJpaEntity entity);
    DevoirJpaEntity toEntity(Devoir domain);
}
