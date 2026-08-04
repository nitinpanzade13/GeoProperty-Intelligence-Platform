from datetime import datetime

from sqlalchemy.orm import Session

from app.database.session import SessionLocal
from app.db_models.village_cache import VillageCache


class VillageCacheRepository:

    def get_by_gis_code(self, gis_code: str):

        db: Session = SessionLocal()

        try:
            return (
                db.query(VillageCache)
                .filter(VillageCache.gis_code == gis_code)
                .first()
            )

        finally:
            db.close()

    def save(
        self,
        gis_code: str,
        geojson: dict,
    ):

        db: Session = SessionLocal()

        try:

            survey_count = len(
                geojson.get("features", [])
            )

            existing = (
                db.query(VillageCache)
                .filter(VillageCache.gis_code == gis_code)
                .first()
            )

            if existing:

                existing.geojson = geojson
                existing.survey_count = survey_count
                existing.updated_at = datetime.utcnow()
                existing.last_verified_at = datetime.utcnow()

            else:

                db.add(
                    VillageCache(
                        gis_code=gis_code,
                        survey_count=survey_count,
                        geojson=geojson,
                    )
                )

            db.commit()

        finally:
            db.close()