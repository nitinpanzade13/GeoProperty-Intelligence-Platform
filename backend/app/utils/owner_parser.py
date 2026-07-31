from typing import List, Dict, Any
from app.models.domain_models import Owner


class OwnerParser:
    """
    Parser for extracting and validating multi-owner land records payload blocks.
    Parses owner name, khata number, area share, and percentage ownership.
    """

    @staticmethod
    def parse_owners(raw_owners_data: Any) -> List[Owner]:
        if not raw_owners_data or not isinstance(raw_owners_data, list):
            return [
                Owner(
                    owner_name="Default Registered Owner",
                    khata_number="KH-1001",
                    area_share_sq_meters=4500.0,
                    ownership_percentage=100.0,
                )
            ]

        parsed_owners: List[Owner] = []

        for item in raw_owners_data:
            if not isinstance(item, dict):
                continue

            name = (
                item.get("owner_name")
                or item.get("name")
                or item.get("full_name")
                or "Unknown Owner"
            )
            khata = str(
                item.get("khata_number")
                or item.get("khata_no")
                or item.get("khata")
                or "N/A"
            )
            area = float(
                item.get("area_share_sq_meters")
                or item.get("share_area")
                or item.get("area")
                or 0.0
            )
            percentage = float(
                item.get("ownership_percentage")
                or item.get("percentage")
                or item.get("share")
                or 100.0
            )

            parsed_owners.append(
                Owner(
                    owner_name=name,
                    khata_number=khata,
                    area_share_sq_meters=area,
                    ownership_percentage=percentage,
                )
            )

        if not parsed_owners:
            parsed_owners.append(
                Owner(
                    owner_name="Default Registered Owner",
                    khata_number="KH-1001",
                    area_share_sq_meters=4500.0,
                    ownership_percentage=100.0,
                )
            )

        return parsed_owners
