package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.notification.Notification;
import com.mbem.mbemlevel.infrastructure.persistence.entity.NotificationJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface NotificationJpaMapper {
    Notification toDomain(NotificationJpaEntity entity);
    NotificationJpaEntity toEntity(Notification domain);
}
