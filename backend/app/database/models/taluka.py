from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class Taluka(Base):
    __tablename__ = "talukas"

    taluka_code = Column(
        String(20),
        primary_key=True,
    )

    taluka_name = Column(
        String(150),
        nullable=False,
    )

    district_code = Column(
        String(10),
        ForeignKey(
            "districts.district_code",
            ondelete="CASCADE",
        ),
        primary_key=True,
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )