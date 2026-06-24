package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ProgressionJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface ProgressionJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Progression toDomain(ProgressionJpaEntity entity);

    ProgressionJpaEntity toEntity(Progression domain);
}
