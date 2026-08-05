from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class District(Base):
    __tablename__ = "districts"

    district_code = Column(
        String(10),
        primary_key=True,
        index=True,
    )

    district_name = Column(
        String(150),
        nullable=False,
    )

    state_code = Column(
        String(5),
        ForeignKey(
            "states.state_code",
            ondelete="CASCADE",
        ),
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )