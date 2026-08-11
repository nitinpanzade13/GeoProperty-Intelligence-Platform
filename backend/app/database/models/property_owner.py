from sqlalchemy import (
    Column,
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
            "area_share_sq_meters",
            "ownership_percentage",
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

    area_share_sq_meters = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    ownership_percentage = Column(
        Float,
        nullable=False,
        default=100.0,
    )