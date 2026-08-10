from sqlalchemy import Column, String, Float, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class Property(Base):
    __tablename__ = "properties"

    property_id = Column(
        String(150),
        primary_key=True,
        index=True,
    )

    gis_code = Column(
        String(40),
        ForeignKey(
            "villages.gis_code",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    survey_number = Column(
        String(100),
        nullable=False,
        index=True,
    )

    plot_id = Column(
        String(150),
        nullable=True,
        index=True,
    )

    area_sq_meters = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    pot_kharaba_sq_meters = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    geometry = Column(
        String,
        nullable=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )