package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface CoursJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Cours toDomain(CoursJpaEntity entity);

    CoursJpaEntity toEntity(Cours domain);
}
