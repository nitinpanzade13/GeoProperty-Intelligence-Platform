import json
from typing import List, Dict, Any

from sqlalchemy.orm import Session

from app.database.session import SessionLocal
from app.database.models.property import Property
from app.database.models.property_owner import PropertyOwner


class PropertyCacheRepository:

    def __init__(self):
        self.db: Session = SessionLocal()

    def close(self):
        self.db.close()

    def count_by_gis_code(self, gis_code: str) -> int:
        return (
            self.db.query(Property)
            .filter(Property.gis_code == gis_code)
            .count()
        )

    def upsert_properties(
        self,
        properties: List[Dict[str, Any]],
    ) -> int:

        saved_count = 0

        try:

            for item in properties:

                property_data = item["property"]

                property_id = property_data.property_id

                # -------------------------------------------------
                # Convert polygon to GeoJSON geometry
                # -------------------------------------------------

                geometry = None

                if (
                    property_data.polygon is not None
                    and property_data.polygon.points
                ):

                    coordinates = [
                        [
                            point.longitude,
                            point.latitude,
                        ]
                        for point in property_data.polygon.points
                    ]

                    # GeoJSON polygon must be closed
                    if coordinates[0] != coordinates[-1]:
                        coordinates.append(coordinates[0])

                    geometry = json.dumps(
                        {
                            "type": "Polygon",
                            "coordinates": [coordinates],
                        }
                    )

                # -------------------------------------------------
                # Find existing property
                # -------------------------------------------------

                db_property = (
                    self.db.query(Property)
                    .filter(
                        Property.property_id == property_id
                    )
                    .first()
                )

                if db_property:

                    db_property.gis_code = property_data.gis_code

                    db_property.survey_number = (
                        property_data.survey_number
                    )

                    db_property.plot_id = (
                        property_data.plot_id
                    )

                    db_property.area_sq_meters = (
                        property_data.area_sq_meters
                    )

                    db_property.geometry = geometry

                else:

                    db_property = Property(
                        property_id=property_data.property_id,
                        gis_code=property_data.gis_code,
                        survey_number=property_data.survey_number,
                        plot_id=property_data.plot_id,
                        area_sq_meters=property_data.area_sq_meters,
                        geometry=geometry,
                    )

                    self.db.add(db_property)

                # -------------------------------------------------
                # Replace existing owners
                # -------------------------------------------------

                self.db.query(PropertyOwner).filter(
                    PropertyOwner.property_id == property_id
                ).delete(
                    synchronize_session=False
                )

                # -------------------------------------------------
                # Deduplicate owners
                # -------------------------------------------------

                unique_owners = set()

                for owner in property_data.owners:

                    owner_key = (
                        property_id,
                        owner.owner_name,
                        owner.khata_number,
                        owner.total_area,
                        owner.pot_kharaba,
                    )

                    if owner_key in unique_owners:
                        continue

                    unique_owners.add(owner_key)

                    # -------------------------------------------------
                    # Save owner
                    # -------------------------------------------------

                    db_owner = PropertyOwner(
                        property_id=property_id,
                        owner_name=owner.owner_name,
                        khata_number=owner.khata_number,
                        total_area=owner.total_area,
                        pot_kharaba=owner.pot_kharaba,
                    )

                    self.db.add(db_owner)

                saved_count += 1

            # -------------------------------------------------
            # Commit everything
            # -------------------------------------------------

            self.db.commit()

            return saved_count

        except Exception:

            self.db.rollback()
            raise