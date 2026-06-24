package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.session.Session;
import com.mbem.mbemlevel.infrastructure.persistence.entity.SessionJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface SessionJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Session toDomain(SessionJpaEntity entity);

    SessionJpaEntity toEntity(Session domain);
}
