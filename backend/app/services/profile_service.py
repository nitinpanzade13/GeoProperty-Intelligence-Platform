from app.repositories.mock_repository import MockDataRepository, mock_repository
from app.schemas.user import UserSchema


class ProfileService:
    def __init__(self, repository: MockDataRepository = mock_repository):
        self.repository = repository

    async def get_user_profile(self) -> UserSchema:
        return await self.repository.get_user_profile()
