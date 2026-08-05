from datetime import datetime
from typing import Optional

from sqlalchemy.orm import Session

from app.database.session import SessionLocal
from app.database.models.village_map_cache import VillageMapCache


class VillageMapCacheRepository:
    """
    Handles PostgreSQL cache for village GeoJSON.

    Future:
    - District cache
    - Taluka cache
    - Village metadata cache
    """

    def __init__(self):
        self.db: Session = SessionLocal()

    def close(self):
        self.db.close()

    def get_village_map(self, gis_code: str) -> Optional[VillageMapCache]:
        return (
            self.db.query(VillageMapCache)
            .filter(VillageMapCache.gis_code == gis_code)
            .first()
        )

    def upsert_village_map(
        self,
        gis_code: str,
        geojson: dict,
        survey_count: int,
    ) -> VillageMapCache:

        cache = (
            self.db.query(VillageMapCache)
            .filter(VillageMapCache.gis_code == gis_code)
            .first()
        )

        if cache:

            cache.geojson = geojson
            cache.survey_count = survey_count
            cache.last_verified_at = datetime.utcnow()

        else:

            cache = VillageMapCache(
                gis_code=gis_code,
                geojson=geojson,
                survey_count=survey_count,
                last_verified_at=datetime.utcnow(),
            )

            self.db.add(cache)

        self.db.commit()
        self.db.refresh(cache)

        return cache

    def delete_village_map(self, gis_code: str):

        cache = (
            self.db.query(VillageMapCache)
            .filter(VillageMapCache.gis_code == gis_code)
            .first()
        )

        if cache:
            self.db.delete(cache)
            self.db.commit()