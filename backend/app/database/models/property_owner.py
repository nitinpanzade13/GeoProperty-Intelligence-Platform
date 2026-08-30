from sqlalchemy import (
    Column,
    Numeric,
    String,
    Float,
    Integer,
    ForeignKey,
    Text,
    UniqueConstraint,
)

from app.database.base import Base


class PropertyOwner(Base):
    __tablename__ = "property_owners"

    __table_args__ = (
        UniqueConstraint(
            "property_id",
            "owner_name",
            "khata_number",
            "total_area",
            "pot_kharaba",
            name="uq_property_owner_record",
        ),
    )

    id = Column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    property_id = Column(
        String(150),
        ForeignKey(
            "properties.property_id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    owner_name = Column(
        Text,
        nullable=False,
    )

    khata_number = Column(
        String(100),
        nullable=True,
    )

    total_area = Column(
        Numeric(10, 4), 
        nullable=False,
        default=0,
    )

    pot_kharaba = Column(
        Numeric(10, 4),
        nullable=False, 
        default=0,
    )