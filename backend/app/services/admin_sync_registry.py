from __future__ import annotations

from typing import Any, Dict
from datetime import datetime, timezone


class AdminSyncRegistry:
    """
    In-memory registry for long-running admin synchronization jobs.

    This is intentionally NOT database-backed.

    It exists only to keep the frontend informed about a currently
    running synchronization job.
    """

    def __init__(self):
        self._jobs: Dict[str, Dict[str, Any]] = {}

    def start(
        self,
        district_code: str,
        force_refresh: bool = False,
    ) -> Dict[str, Any]:
        district_code = str(district_code).strip()

        existing = self._jobs.get(district_code)

        if existing and existing.get("sync_status") == "syncing":
            return dict(existing)

        job = {
            "district_code": district_code,
            "sync_status": "syncing",
            "sync_in_progress": True,

            "total_talukas": 0,
            "total_villages": 0,

            "processed_villages": 0,
            "skipped_villages": 0,
            "successful_villages": 0,
            "failed_villages": 0,
            "pending_villages": 0,

            "progress_percent": 0,

            "force_refresh": force_refresh,

            "message": "District synchronization started.",

            "started_at": datetime.now(
                timezone.utc
            ).isoformat(),

            "completed_at": None,

            "failed": [],
        }

        self._jobs[district_code] = job

        return dict(job)

    def is_running(
        self,
        district_code: str,
    ) -> bool:
        job = self._jobs.get(
            str(district_code).strip()
        )

        return bool(
            job
            and job.get("sync_status") == "syncing"
        )

    def get(
        self,
        district_code: str,
    ) -> Dict[str, Any] | None:
        job = self._jobs.get(
            str(district_code).strip()
        )

        if job is None:
            return None

        return dict(job)

    def update_totals(
        self,
        district_code: str,
        *,
        total_talukas: int | None = None,
        total_villages: int | None = None,
    ):
        job = self._jobs.get(
            str(district_code).strip()
        )

        if not job:
            return

        if total_talukas is not None:
            job["total_talukas"] = total_talukas

        if total_villages is not None:
            job["total_villages"] = total_villages
            job["pending_villages"] = max(
                0,
                total_villages
                - job["processed_villages"],
            )

    def record_village(
        self,
        district_code: str,
        result: Dict[str, Any],
    ):
        job = self._jobs.get(
            str(district_code).strip()
        )

        if not job:
            return

        job["processed_villages"] += 1

        if result.get("success"):
            if result.get("skipped"):
                job["skipped_villages"] += 1
            else:
                job["successful_villages"] += 1
        else:
            job["failed_villages"] += 1

            failed = job.setdefault(
                "failed",
                [],
            )

            failed.append({
                "gis_code": result.get("gis_code"),
                "village_name": result.get(
                    "village_name"
                ),
                "error": result.get(
                    "error",
                    "Village synchronization failed.",
                ),
            })

        total = job.get(
            "total_villages",
            0,
        )

        processed = job[
            "processed_villages"
        ]

        job["pending_villages"] = max(
            0,
            total - processed,
        )

        if total > 0:
            job["progress_percent"] = round(
                (
                    processed
                    / total
                ) * 100,
                1,
            )

    def finish(
        self,
        district_code: str,
        result: Dict[str, Any],
    ):
        district_code = str(
            district_code
        ).strip()

        job = self._jobs.get(
            district_code
        )

        if not job:
            return

        failed = int(
            result.get(
                "failed_villages",
                job.get(
                    "failed_villages",
                    0,
                ),
            )
        )

        successful = int(
            result.get(
                "successful_villages",
                job.get(
                    "successful_villages",
                    0,
                ),
            )
        )

        total = int(
            result.get(
                "total_villages",
                job.get(
                    "total_villages",
                    0,
                ),
            )
        )

        if failed == 0 and total > 0:
            status = "synced"
        elif successful > 0 and failed > 0:
            status = "partially_synced"
        elif failed > 0:
            status = "not_synced"
        else:
            status = "not_synced"

        job.update({
            "sync_status": status,
            "sync_in_progress": False,

            "total_talukas": result.get(
                "total_talukas",
                job.get("total_talukas", 0),
            ),

            "total_villages": total,

            "skipped_villages": result.get(
                "skipped_villages",
                job.get("skipped_villages", 0),
            ),

            "successful_villages": successful,

            "failed_villages": failed,

            "pending_villages": 0,

            "progress_percent": (
                100
                if total > 0
                else 0
            ),

            "failed": result.get(
                "failed",
                job.get("failed", []),
            ),

            "message": (
                "District synchronization completed."
                if failed == 0
                else
                "District synchronization completed with failures."
            ),

            "completed_at": datetime.now(
                timezone.utc
            ).isoformat(),
        })

    def fail(
        self,
        district_code: str,
        error: str,
    ):
        job = self._jobs.get(
            str(district_code).strip()
        )

        if not job:
            return

        job.update({
            "sync_status": "not_synced",
            "sync_in_progress": False,
            "message": error,
            "completed_at": datetime.now(
                timezone.utc
            ).isoformat(),
        })


admin_sync_registry = AdminSyncRegistry()