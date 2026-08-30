import re
from typing import List, Any

from app.models.domain_models import Owner


class OwnerParser:
    """
    Parses owner information from Maharashtra BhuNaksha
    getPlotInfo 'info' text or structured owner JSON.

    Expected text structure:

        Survey No. : 113
        Total Area : 0.9800
        Pot kharaba : 0.0000
        Owner Name : Some Owner
        Khata No. : 118

    Each owner/info block is converted into one Owner object.
    """

    # ---------------------------------------------------------
    # Text field patterns
    # ---------------------------------------------------------

    OWNER_PATTERN = re.compile(
        r"(?:Owner\s*Name|Khatedar\s*Name|Owner|Hakkadar|"
        r"खातेदाराचे\s*नाव|मालकाचे\s*नाव|नाव)"
        r"\s*[:=]?\s*(.+)",
        re.IGNORECASE,
    )

    KHATA_PATTERN = re.compile(
        r"(?:Khata\s*No\.?|Khata\s*Number|Khata|"
        r"खाता\s*क्र\.?|खाते\s*क्र\.?)"
        r"\s*[:.]?\s*(.+)",
        re.IGNORECASE,
    )

    TOTAL_AREA_PATTERN = re.compile(
        r"(?:Total\s*Area|TotalArea|"
        r"एकूण\s*क्षेत्र|एकुण\s*क्षेत्र)"
        r"\s*[:=]?\s*([\d.,]+)",
        re.IGNORECASE,
    )

    POT_KHARABA_PATTERN = re.compile(
        r"(?:Pot\s*Kharaba|PotKharaba|"
        r"Pot\s*Kharab|Kharaba|"
        r"पोट\s*खराबा|पोटखराबा)"
        r"\s*[:=]?\s*([\d.,]+)",
        re.IGNORECASE,
    )

    # ---------------------------------------------------------
    # Public parser
    # ---------------------------------------------------------

    @staticmethod
    def parse_owners(raw_owners_data: Any) -> List[Owner]:
        """
        Parse owners from either:

        1. Structured JSON list
        2. BhuNaksha info text string
        """

        if raw_owners_data is None:
            return []

        if isinstance(raw_owners_data, list):
            return OwnerParser._parse_json(raw_owners_data)

        if isinstance(raw_owners_data, str):
            if not raw_owners_data.strip():
                return []

            return OwnerParser._parse_text(raw_owners_data)

        return []

    # ---------------------------------------------------------
    # JSON parser
    # ---------------------------------------------------------

    @staticmethod
    def _parse_json(items: List[Any]) -> List[Owner]:
        owners: List[Owner] = []

        for item in items:

            if not isinstance(item, dict):
                continue

            owner_name = str(
                OwnerParser._first_value(
                    item,
                    "owner_name",
                    "name",
                    "full_name",
                )
                or "Unknown Owner"
            ).strip()

            khata_number = str(
                OwnerParser._first_value(
                    item,
                    "khata_number",
                    "khata_no",
                    "khata",
                )
                or ""
            ).strip()

            total_area = OwnerParser._to_float(
                OwnerParser._first_value(
                    item,
                    "total_area",
                    "totalArea",
                    "area",
                    "area_sq_meters",
                )
            )

            pot_kharaba = OwnerParser._to_float(
                OwnerParser._first_value(
                    item,
                    "pot_kharaba",
                    "potKharaba",
                    "pot_kharaba_sq_meters",
                    "kharaba",
                )
            )

            owners.append(
                Owner(
                    owner_name=owner_name,
                    khata_number=khata_number,
                    total_area=total_area,
                    pot_kharaba=pot_kharaba,
                )
            )

        return owners

    # ---------------------------------------------------------
    # Text parser
    # ---------------------------------------------------------

    @staticmethod
    def _parse_text(text: str) -> List[Owner]:
        """
        Parse Maharashtra BhuNaksha getPlotInfo 'info' text.

        Every Owner Name starts a new owner record.

        Example:

            Total Area : 0.9800
            Pot kharaba : 0.0000
            Owner Name : ABC
            Khata No. : 118

            Total Area : 0.0000
            Pot kharaba : 0.0800
            Owner Name : XYZ
            Khata No. : 424

        becomes:

            Owner(
                owner_name="ABC",
                khata_number="118",
                total_area=0.98,
                pot_kharaba=0.0
            )

            Owner(
                owner_name="XYZ",
                khata_number="424",
                total_area=0.0,
                pot_kharaba=0.08
            )
        """

        owners: List[Owner] = []

        # Remove HTML tags that BhuNaksha may return.
        text = re.sub(r"<[^>]+>", "\n", text)

        # Normalize line endings.
        text = text.replace("\r", "")

        # -----------------------------------------------------
        # Current owner state
        # -----------------------------------------------------

        current_owner = None
        current_khata = ""
        current_total_area = 0.0
        current_pot_kharaba = 0.0

        # -----------------------------------------------------
        # Save current owner
        # -----------------------------------------------------

        def flush_current_owner() -> None:
            nonlocal current_owner
            nonlocal current_khata
            nonlocal current_total_area
            nonlocal current_pot_kharaba

            if current_owner is None:
                return

            owners.append(
                Owner(
                    owner_name=current_owner,
                    khata_number=current_khata,
                    total_area=current_total_area,
                    pot_kharaba=current_pot_kharaba,
                )
            )

            current_owner = None
            current_khata = ""
            current_total_area = 0.0
            current_pot_kharaba = 0.0

        # -----------------------------------------------------
        # Parse every line
        # -----------------------------------------------------

        for raw_line in text.split("\n"):

            line = raw_line.strip()

            if not line:
                continue

            # ---------------------------------------------
            # Total Area
            # ---------------------------------------------

            total_area_match = (
                OwnerParser.TOTAL_AREA_PATTERN.search(line)
            )

            if total_area_match:

                current_total_area = OwnerParser._to_float(
                    total_area_match.group(1)
                )

                continue

            # ---------------------------------------------
            # Pot Kharaba
            # ---------------------------------------------

            pot_kharaba_match = (
                OwnerParser.POT_KHARABA_PATTERN.search(line)
            )

            if pot_kharaba_match:

                current_pot_kharaba = OwnerParser._to_float(
                    pot_kharaba_match.group(1)
                )

                continue

            # ---------------------------------------------
            # Owner
            # ---------------------------------------------

            owner_match = OwnerParser.OWNER_PATTERN.search(line)

            if owner_match:

                # Finish previous owner before starting
                # the next owner record.
                flush_current_owner()

                current_owner = (
                    owner_match.group(1).strip()
                )

                continue

            # ---------------------------------------------
            # Khata
            # ---------------------------------------------

            khata_match = (
                OwnerParser.KHATA_PATTERN.search(line)
            )

            if khata_match:

                current_khata = (
                    khata_match.group(1)
                    .replace(":", "")
                    .replace(".", "")
                    .strip()
                )

                continue

        # -----------------------------------------------------
        # Save final owner
        # -----------------------------------------------------

        flush_current_owner()

        return owners

    # ---------------------------------------------------------
    # First non-None value helper
    # ---------------------------------------------------------

    @staticmethod
    def _first_value(
        item: dict,
        *keys: str,
    ) -> Any:
        """
        Return the first value whose key exists and whose
        value is not None.

        This deliberately does NOT use `or`, because 0 and
        0.0 are valid land-area values.
        """

        for key in keys:

            if key in item and item[key] is not None:
                return item[key]

        return None

    # ---------------------------------------------------------
    # Numeric conversion helper
    # ---------------------------------------------------------

    @staticmethod
    def _to_float(value: Any) -> float:
        """
        Safely convert values such as:

            0.9800
            "0.9800"
            "1,234.50"
            0
            None

        into float.
        """

        if value is None:
            return 0.0

        try:

            value = str(value).strip()

            if not value:
                return 0.0

            # Remove thousands separators.
            value = value.replace(",", "")

            return float(value)

        except (ValueError, TypeError):
            return 0.0