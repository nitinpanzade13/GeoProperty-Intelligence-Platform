from sqlalchemy.orm import Session

from app.database.models import (
    District,
    Taluka,
    Village,
)


class DatabaseRepository:
    def __init__(self, db: Session):
        self.db = db

    # -------------------------
    # DISTRICTS
    # -------------------------

    def get_districts(self):
        return self.db.query(District).all()

    def save_districts(self, districts):
        for district in districts:
            exists = (
                self.db.query(District)
                .filter(
                    District.district_code == district.district_code
                )
                .first()
            )

            if exists:
                continue

            self.db.add(
                District(
                    district_code=district.district_code,
                    district_name=district.district_name,
                    state_code=district.state_code,
                )
            )

        self.db.commit()

    # -------------------------
    # TALUKAS
    # -------------------------

    def get_talukas(self, district_code: str):
        return (
            self.db.query(Taluka)
            .filter(Taluka.district_code == district_code)
            .all()
        )

    def save_talukas(self, talukas):
        for taluka in talukas:
            exists = (
                self.db.query(Taluka)
                .filter(
                    Taluka.taluka_code == taluka.taluka_code
                )
                .first()
            )

            if exists:
                continue

            self.db.add(
                Taluka(
                    taluka_code=taluka.taluka_code,
                    taluka_name=taluka.taluka_name,
                    district_code=taluka.district_code,
                )
            )

        self.db.commit()

    # -------------------------
    # VILLAGES
    # -------------------------

    def get_villages(self, taluka_code: str):
        return (
            self.db.query(Village)
            .filter(Village.taluka_code == taluka_code)
            .all()
        )

    def save_villages(self, villages):
        for village in villages:
            exists = (
                self.db.query(Village)
                .filter(
                    Village.gis_code == village.gis_code
                )
                .first()
            )

            if exists:
                continue

            self.db.add(
                Village(
                    gis_code=village.gis_code,
                    village_code=village.village_code,
                    village_name=village.village_name,
                    taluka_code=village.taluka_code,
                )
            )

        self.db.commit()