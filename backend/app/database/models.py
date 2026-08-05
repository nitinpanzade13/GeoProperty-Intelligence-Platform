from sqlalchemy import Column, String, DateTime, ForeignKey, JSON, Integer
from sqlalchemy.sql import func
from app.database.database import Base


class State(Base):
    __tablename__ = "states"

    state_code = Column(String(5), primary_key=True, index=True)
    state_name = Column(String(100), nullable=False)


class District(Base):
    __tablename__ = "districts"

    district_code = Column(String(10), primary_key=True, index=True)
    district_name = Column(String(150), nullable=False)

    state_code = Column(
        String(5),
        ForeignKey("states.state_code", ondelete="CASCADE"),
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )


class Taluka(Base):
    __tablename__ = "talukas"

    taluka_code = Column(String(20), primary_key=True, index=True)

    taluka_name = Column(String(150), nullable=False)

    district_code = Column(
        String(10),
        ForeignKey("districts.district_code", ondelete="CASCADE"),
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )


class Village(Base):
    __tablename__ = "villages"

    gis_code = Column(String(40), primary_key=True, index=True)

    village_code = Column(String(20), nullable=False)

    village_name = Column(String(200), nullable=False)

    taluka_code = Column(
        String(20),
        ForeignKey("talukas.taluka_code", ondelete="CASCADE"),
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )


class VillageMapCache(Base):
    __tablename__ = "village_map_cache"

    gis_code = Column(String(40), primary_key=True)

    geojson = Column(JSON, nullable=False)

    total_surveys = Column(Integer, nullable=False)

    cached_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )