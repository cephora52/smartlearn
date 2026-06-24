package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.certificat.Certificat;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CertificatJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface CertificatJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Certificat toDomain(CertificatJpaEntity entity);

    CertificatJpaEntity toEntity(Certificat domain);
}
