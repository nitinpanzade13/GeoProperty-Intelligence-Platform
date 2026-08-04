from datetime import datetime

from sqlalchemy import Column
from sqlalchemy import Integer
from sqlalchemy import String
from sqlalchemy import DateTime
from sqlalchemy import JSON

from app.database.base import Base


class VillageCache(Base):
    __tablename__ = "village_cache"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    gis_code = Column(
        String,
        unique=True,
        nullable=False,
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
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )

    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    last_verified_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )