from datetime import datetime, timedelta, timezone


def is_cache_stale(
    last_verified_at: datetime,
    refresh_days: int,
) -> bool:
    """
    Returns True if the cached data should be refreshed.
    """

    if last_verified_at is None:
        return True

    now = datetime.now(timezone.utc)

    return (
        now - last_verified_at
    ) > timedelta(days=refresh_days)