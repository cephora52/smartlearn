package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import com.mbem.mbemlevel.api.dto.response.AvisCoursResponse;
import org.mapstruct.*;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface AvisCoursJpaMapper {
    AvisCoursResponse toResponse(AvisCoursJpaEntity entity);
}
