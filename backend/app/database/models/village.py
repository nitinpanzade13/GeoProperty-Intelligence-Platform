from sqlalchemy import (
    Column,
    String,
    DateTime,
    ForeignKey,
    ForeignKeyConstraint,
)
from sqlalchemy.sql import func

from app.database.base import Base


class Village(Base):
    __tablename__ = "villages"

    # ============================================================
    # PRIMARY KEY
    # ============================================================

    gis_code = Column(
        String(40),
        primary_key=True,
        index=True,
    )

    # ============================================================
    # VILLAGE DATA
    # ============================================================

    village_code = Column(
        String(20),
        nullable=False,
    )

    village_name = Column(
        String(200),
        nullable=False,
    )

    # ============================================================
    # DISTRICT
    # ============================================================

    district_code = Column(
        String(20),
        ForeignKey(
            "districts.district_code",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    # ============================================================
    # TALUKA
    # ============================================================

    taluka_code = Column(
        String(20),
        nullable=False,
        index=True,
    )

    # ============================================================
    # COMPOSITE FOREIGN KEY
    #
    # A taluka is uniquely identified by:
    #
    #     district_code + taluka_code
    #
    # Therefore village must reference BOTH columns.
    # ============================================================

    __table_args__ = (
        ForeignKeyConstraint(
            ["district_code", "taluka_code"],
            ["talukas.district_code", "talukas.taluka_code"],
            ondelete="CASCADE",
            name="fk_village_taluka",
        ),
    )

    # ============================================================
    # CREATED AT
    # ============================================================

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )