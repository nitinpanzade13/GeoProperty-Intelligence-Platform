from sqlalchemy import (
    Column,
    String,
    Integer,
    JSON,
    DateTime,
)

from sqlalchemy.sql import func

from app.database.base import Base


class VillageMapCache(Base):
    __tablename__ = "village_map_cache"

    gis_code = Column(
        String(40),
        primary_key=True,
        index=True,
    )

    survey_count = Column(
        Integer,
        nullable=False,
        default=0,
    )

    geojson = Column(
        JSON,
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    last_verified_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )