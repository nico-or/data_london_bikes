# Dates

## NULL Start or End Date

We check that no records have `NULL` `date_start` o `date_end`.

```sql
SELECT COUNT(*) as null_date_count
FROM trips_raw
WHERE date_start IS NULL
OR date_end IS NULL;
```

| null_date_count |
| --------------: |
|               0 |

## Date ranges

```sql
WITH trip_dates AS(
    SELECT date_start AS trip_date FROM trips_raw
    UNION
    SELECT date_end AS trip_date FROM trips_raw
)
SELECT MIN(trip_date), MAX(trip_date)
FROM trip_dates;
```

| min(trip_date)      | max(trip_date)      |
| ------------------- | ------------------- |
| 2024-01-01 00:01:00 | 2025-02-02 14:38:00 |

We find that no trip record started on 2023 and that some trips ended on 2025, so we verify that all those trips effectively started on 2024.

```sql
SELECT
    YEAR(date_start) as start_year,
    COUNT() as trip_count
FROM trips_raw
WHERE YEAR(date_end) = 2025
GROUP BY start_year;
```

| start_year | trip_count |
| ---------: | ---------: |
|       2024 |        328 |

They do, so we consider all those records as part of 2024.
