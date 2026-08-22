from sqlalchemy import func, distinct

from app.database.session import SessionLocal
from app.database.models.district import District
from app.database.models.taluka import Taluka
from app.database.models.village import Village
from app.database.models.property import Property
from app.database.models.property_owner import PropertyOwner
from app.database.models.village_map_cache import VillageMapCache


class AdminDashboardRepository:
    """
    Repository for aggregate statistics used by the admin dashboard.

    This repository only reads from PostgreSQL.
    It does not trigger remote BhuNaksha API calls.
    """

    def __init__(self):
        self.db = SessionLocal()

    def close(self):
        self.db.close()

    def get_summary(self) -> dict:
        return {
            "districts": self._count(District),
            "talukas": self._count(Taluka),
            "villages": self._count(Village),
            "properties": self._count(Property),
            "owners": self._count(PropertyOwner),
            "village_maps": self._count(VillageMapCache),
        }

    def get_district_overview(self) -> list[dict]:
        rows = (
            self.db.query(
                District.district_code,
                District.district_name,
                func.count(
                    distinct(Taluka.taluka_code)
                ).label("taluka_count"),
                func.count(
                    distinct(Village.gis_code)
                ).label("village_count"),
                func.count(
                    distinct(VillageMapCache.gis_code)
                ).label("map_count"),
            )
            .outerjoin(
                Taluka,
                Taluka.district_code == District.district_code,
            )
            .outerjoin(
                Village,
                Village.district_code == District.district_code,
            )
            .outerjoin(
                VillageMapCache,
                VillageMapCache.gis_code == Village.gis_code,
            )
            .group_by(
                District.district_code,
                District.district_name,
            )
            .order_by(District.district_code)
            .all()
        )

        result = []

        for row in rows:
            taluka_count = row.taluka_count or 0
            village_count = row.village_count or 0
            map_count = row.map_count or 0

            if village_count == 0:
                sync_status = "not_synced"
            elif map_count < village_count:
                sync_status = "partially_synced"
            else:
                sync_status = "synced"

            result.append(
                {
                    "district_code": row.district_code,
                    "district_name": row.district_name,
                    "taluka_count": taluka_count,
                    "village_count": village_count,
                    "map_count": map_count,
                    "sync_status": sync_status,
                }
            )

        return result

    def _count(self, model) -> int:
        return (
            self.db.query(func.count())
            .select_from(model)
            .scalar()
            or 0
        )

    def get_taluka_overview(
        self,
        district_code: str,
    ) -> list[dict]:
        rows = (
            self.db.query(
                Taluka.taluka_code,
                Taluka.taluka_name,
                func.count(
                    distinct(Village.gis_code)
                ).label("village_count"),
                func.count(
                    distinct(VillageMapCache.gis_code)
                ).label("map_count"),
            )
            .outerjoin(
                Village,
                (
                    Village.district_code == Taluka.district_code
                )
                & (
                    Village.taluka_code == Taluka.taluka_code
                ),
            )
            .outerjoin(
                VillageMapCache,
                VillageMapCache.gis_code == Village.gis_code,
            )
            .filter(
                Taluka.district_code == district_code,
            )
            .group_by(
                Taluka.taluka_code,
                Taluka.taluka_name,
            )
            .order_by(Taluka.taluka_name)
            .all()
        )

        result = []

        for row in rows:
            village_count = row.village_count or 0
            map_count = row.map_count or 0

            if village_count == 0:
                sync_status = "not_synced"
            elif map_count < village_count:
                sync_status = "partially_synced"
            else:
                sync_status = "synced"

            result.append(
                {
                    "taluka_code": row.taluka_code,
                    "taluka_name": row.taluka_name,
                    "village_count": village_count,
                    "map_count": map_count,
                    "sync_status": sync_status,
                }
            )

        return result

    def get_village_overview(
        self,
        district_code: str,
        taluka_code: str,
    ) -> list[dict]:
        rows = (
            self.db.query(
                Village.gis_code,
                Village.village_name,
                Village.taluka_code,
                # Property count for each village
                func.count(
                    distinct(Property.property_id)
                ).label("property_count"),

                #owner count for each village
                func.count(
                    distinct(PropertyOwner.id)
                ).label("owner_count"),

                #Survey count from village_map_cache for each village
                func.coalesce(
                    VillageMapCache.survey_count, 0,
                ).label("survey_count"),

                # Map status for each village
                VillageMapCache.gis_code.label("map_gis_code"),
            )
            # village -> property 
            .outerjoin(
                Property,
                Property.gis_code == Village.gis_code,
            )
            # property -> owners
            .outerjoin(
                PropertyOwner,
                PropertyOwner.property_id == Property.property_id,
            )
            # village -> village_map_cache
            .outerjoin(
                VillageMapCache,
                VillageMapCache.gis_code == Village.gis_code,
            )
            .filter(
                Village.district_code == district_code,
                Village.taluka_code == taluka_code,
            )
            .group_by(
                Village.gis_code,
                Village.village_name,
                Village.taluka_code,
                VillageMapCache.gis_code,
            )
            .order_by(Village.village_name)
            .all()
        )

        result = []

        for row in rows:
            property_count = row.property_count or 0
            owner_count = row.owner_count or 0
            survey_count = row.survey_count or 0
            
            map_status = (
                "synced"
                if row.map_gis_code is not None
                else "not_synced"
            )

            result.append(
                {
                    "gis_code": row.gis_code,
                    "village_name": row.village_name,
                    "taluka_code": row.taluka_code,
                    "property_count": property_count,
                    "owner_count": owner_count,
                    "survey_count": survey_count,
                    "map_status": map_status,
                }
            )

        return result