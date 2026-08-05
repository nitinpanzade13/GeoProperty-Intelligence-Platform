from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class Village(Base):
    __tablename__ = "villages"

    gis_code = Column(
        String(40),
        primary_key=True,
        index=True,
    )

    village_code = Column(
        String(20),
        nullable=False,
    )

    village_name = Column(
        String(200),
        nullable=False,
    )

    taluka_code = Column(
        String(20),
        ForeignKey(
            "talukas.taluka_code",
            ondelete="CASCADE",
        ),
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )