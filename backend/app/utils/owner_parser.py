import re
from typing import List, Any

from app.models.domain_models import Owner


class OwnerParser:
    """
    Parses owner information from Bhunaksha getPlotInfo 'info' text
    or from structured owner JSON.
    """

    OWNER_PATTERN = re.compile(
        r"(?:Owner\s*Name|Khatedar\s*Name|Owner|Hakkadar|"
        r"खातेदाराचे\s*नाव|मालकाचे\s*नाव|नाव)\s*[:=]?\s*(.+)",
        re.IGNORECASE,
    )

    KHATA_PATTERN = re.compile(
        r"(?:Khata\s*No\.?|Khata\s*Number|Khata|"
        r"खाता\s*क्र\.?|खाते\s*क्र\.?)\s*[:.]?\s*(.+)",
        re.IGNORECASE,
    )

    @staticmethod
    def parse_owners(raw_owners_data: Any) -> List[Owner]:

        if not raw_owners_data:
            return []

        if isinstance(raw_owners_data, list):
            return OwnerParser._parse_json(raw_owners_data)

        if isinstance(raw_owners_data, str):
            return OwnerParser._parse_text(raw_owners_data)

        return []

    @staticmethod
    def _parse_json(items: List[Any]) -> List[Owner]:

        owners: List[Owner] = []

        for item in items:

            if not isinstance(item, dict):
                continue

            owners.append(
                Owner(
                    owner_name=str(
                        item.get("owner_name")
                        or item.get("name")
                        or item.get("full_name")
                        or "Unknown Owner"
                    ),
                    khata_number=str(
                        item.get("khata_number")
                        or item.get("khata_no")
                        or item.get("khata")
                        or ""
                    ),
                    area_share_sq_meters=float(
                        item.get("area_share_sq_meters")
                        or item.get("share_area")
                        or item.get("area")
                        or 0
                    ),
                    ownership_percentage=float(
                        item.get("ownership_percentage")
                        or item.get("percentage")
                        or item.get("share")
                        or 100
                    ),
                )
            )

        return owners

    @staticmethod
    def _parse_text(text: str) -> List[Owner]:

        owners: List[Owner] = []

        text = re.sub(r"<[^>]+>", "\n", text)
        text = text.replace("\r", "")

        current_owner = None
        current_khata = ""

        for raw_line in text.split("\n"):

            line = raw_line.strip()

            if not line:
                continue

            owner_match = OwnerParser.OWNER_PATTERN.search(line)

            if owner_match:

                if current_owner:
                    owners.append(
                        Owner(
                            owner_name=current_owner,
                            khata_number=current_khata,
                            area_share_sq_meters=0.0,
                            ownership_percentage=100.0,
                        )
                    )

                current_owner = owner_match.group(1).strip()
                current_khata = ""
                continue

            khata_match = OwnerParser.KHATA_PATTERN.search(line)

            if khata_match:
                current_khata = (
                    khata_match.group(1)
                    .replace(":", "")
                    .replace(".", "")
                    .strip()
                )

        if current_owner:
            owners.append(
                Owner(
                    owner_name=current_owner,
                    khata_number=current_khata,
                    area_share_sq_meters=0.0,
                    ownership_percentage=100.0,
                )
            )

        return owners