from sqlalchemy import Column, String

from app.database.base import Base


class State(Base):
    __tablename__ = "states"

    state_code = Column(String(5), primary_key=True, index=True)
    state_name = Column(String(100), nullable=False)