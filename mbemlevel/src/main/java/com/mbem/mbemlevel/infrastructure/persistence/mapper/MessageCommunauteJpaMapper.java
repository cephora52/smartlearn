package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import com.mbem.mbemlevel.infrastructure.persistence.entity.MessageCommunauteJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface MessageCommunauteJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    MessageCommunaute toDomain(MessageCommunauteJpaEntity entity);

    MessageCommunauteJpaEntity toEntity(MessageCommunaute domain);
}
