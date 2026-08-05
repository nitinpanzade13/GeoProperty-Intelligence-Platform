from typing import Generic, List, Type, TypeVar

from sqlalchemy.orm import Session

from app.database.session import SessionLocal

T = TypeVar("T")


class BaseCacheRepository(Generic[T]):
    """
    Generic repository for PostgreSQL metadata cache.
    """

    def __init__(self, model: Type[T]):
        self.model = model
        self.db: Session = SessionLocal()

    def close(self):
        self.db.close()

    def get_all(self) -> List[T]:
        return self.db.query(self.model).all()

    def save_all(self, data: List[T]) -> None:
        self.db.query(self.model).delete()
        self.db.add_all(data)
        self.db.commit()

    def clear(self) -> None:
        self.db.query(self.model).delete()
        self.db.commit()

    def is_cached(self) -> bool:
        return self.db.query(self.model).count() > 0