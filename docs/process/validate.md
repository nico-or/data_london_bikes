# Data Validation

Before applying the final normalization step and dividing the single table into the relational model, we can verify the data coherence.

## Bikes

We check that for every `bike_id` there are only 1 associated `bike_model`.

```sql
SELECT
    bike_id,
    COUNT(DISTINCT bike_model) AS model_variants
FROM trips_raw
GROUP BY bike_id
HAVING model_variants > 1
ORDER BY bike_id;
```

| bike_id | model_variants |
| ------: | -------------: |
|   62308 |              2 |
|   62309 |              2 |
|   62524 |              2 |
|   62598 |              2 |
|   62732 |              2 |
|   62737 |              2 |

Since there are multiple `bike_id` with more than 1 `bike_model` we need to decide on how to consolidate the inconsistency.
For every pair of `bike_id` + `bike_model` we check the count of records and the first and last dates where that combination was recorded.

```sql
WITH target_ids AS (
    SELECT bike_id
    FROM trips_raw
    GROUP BY bike_id
    HAVING COUNT(DISTINCT bike_model) > 1
)
SELECT
    bike_id,
    bike_model,
    COUNT() AS record_count,
    strftime(MIN(date_start), '%Y-%m-%d') AS first_seen,
    strftime(MAX(date_end), '%Y-%m-%d') AS last_seen,
FROM trips_raw
WHERE bike_id IN (SELECT bike_id FROM target_ids)
GROUP BY bike_id, bike_model
ORDER BY bike_id, first_seen;
```

| bike_id | bike_model | record_count | first_seen | last_seen  |
| ------: | ---------- | -----------: | ---------- | ---------- |
|   62308 | CLASSIC    |          272 | 2024-07-05 | 2024-12-25 |
|   62308 | PBSC_EBIKE |           20 | 2024-08-06 | 2024-08-14 |
|   62309 | CLASSIC    |          134 | 2024-07-04 | 2024-09-18 |
|   62309 | PBSC_EBIKE |           11 | 2024-08-01 | 2024-08-06 |
|   62524 | CLASSIC    |           66 | 2024-07-11 | 2024-09-30 |
|   62524 | PBSC_EBIKE |           77 | 2024-10-01 | 2024-12-18 |
|   62598 | CLASSIC    |          209 | 2024-07-30 | 2024-12-26 |
|   62598 | PBSC_EBIKE |           21 | 2024-08-01 | 2024-08-13 |
|   62732 | CLASSIC    |          249 | 2024-07-03 | 2024-12-30 |
|   62732 | PBSC_EBIKE |           24 | 2024-08-01 | 2024-08-14 |
|   62737 | CLASSIC    |          264 | 2024-07-04 | 2024-12-31 |
|   62737 | PBSC_EBIKE |           22 | 2024-08-01 | 2024-08-07 |

We find that for most `bike_id` (except for 62524), the inconsistent records only were registered on the first weeks August of 2024. We will consider that all those records were caused by data input issues, were the incorrect `bike_model` was assigned to a `bike_id`and then reverted back.

The only `bike_id` that don't follow the described pattern is `bike_id` 62524.
This `bike_id` appeared for the first time on July as a `CLASSIC` and on October it was changed to a `PBSC_EBIKE` until December.
We assume that, due to the lack of the back and forth seen in the other `bike_id`, the bike was incorrectly registered as a `CLASSIC` and corrected later.

To fix both of these cases we can assign the _last seen_ bike_model to each `bike_id`.

```sql
WITH bikes_ranked AS (
    SELECT
        bike_id,
        bike_model,
        ROW_NUMBER() OVER (
            PARTITION BY bike_id
            ORDER BY date_end DESC
        ) AS rn
    FROM trips_raw
),
target_ids AS (
    SELECT bike_id
    FROM trips_raw
    GROUP BY bike_id
    HAVING COUNT(DISTINCT bike_model) > 1
)
SELECT
    bike_id,
    bike_model
FROM bikes_ranked
WHERE rn = 1
AND bike_id IN (SELECT bike_id FROM target_ids)
ORDER BY bike_id;
```

| bike_id | bike_model |
| ------: | ---------- |
|   62308 | CLASSIC    |
|   62309 | CLASSIC    |
|   62524 | PBSC_EBIKE |
|   62598 | CLASSIC    |
|   62732 | CLASSIC    |
|   62737 | CLASSIC    |

Removing the lines used to filter the conflicting `bike_id` we arrive at a query that will result in a normalized bikes table.

```sql
WITH bikes_ranked AS (
    SELECT
        bike_id,
        bike_model,
        ROW_NUMBER() OVER (
            PARTITION BY bike_id
            ORDER BY date_end DESC
        ) AS rn
    FROM trips_raw
)
SELECT
    bike_id,
    bike_model
FROM bikes_ranked
WHERE rn = 1
ORDER BY bike_id;
```

## Stations

In a similar fashion, we can check that every `station_id`has a unique `station_name`, with the additional care to merge all `start_station` and `end_station` attributes into a single stations table.

```sql
WITH stations AS (
    SELECT
        station_start_id AS station_id,
        station_start_name AS station_name,
    FROM trips_raw
    UNION
    SELECT
        station_end_id AS station_id,
        station_end_name AS station_name,
    FROM trips_raw
)
SELECT
    station_id,
    COUNT(DISTINCT station_name) AS name_variants
FROM stations
GROUP BY station_id
HAVING name_variants > 1
ORDER BY station_id;
```

| station_id | name_variants |
| ---------: | ------------: |
|        964 |             2 |
|       1006 |             2 |
|     200118 |             2 |
|     300100 |             2 |

```sql
WITH
stations AS (
  SELECT
    station_start_id AS station_id,
    station_start_name AS station_name,
    date_start AS trip_date
  FROM trips_raw
  UNION ALL
  SELECT
    station_end_id AS station_id,
    station_end_name AS station_name,
    date_end AS trip_date
  FROM trips_raw
)
SELECT
  station_id,
  station_name,
  COUNT(*) AS record_count,
  strftime(MIN(trip_date),'%Y-%m-%d') AS first_seen,
  strftime(MAX(trip_date),'%Y-%m-%d') AS  last_seen,
FROM stations
WHERE station_id IN (
    SELECT station_id
    FROM stations
    GROUP BY station_id
    HAVING COUNT(DISTINCT station_name) > 1
)
GROUP BY station_id, station_name
ORDER BY station_id, first_date;
```

| station_id | station_name                       | record_count | first_seen | last_seen  |
| ---------: | ---------------------------------- | -----------: | ---------- | ---------- |
|        964 | Bath Street, St. Luke's            |        25057 | 2024-01-01 | 2024-12-31 |
|        964 | Bath Street, St. Lke's             |        12952 | 2024-05-01 | 2024-08-26 |
|       1006 | Bayley Street , Bloomsbury         |        21419 | 2024-01-01 | 2024-09-30 |
|       1006 | Percy Street, Bloomsbury           |         6506 | 2024-10-01 | 2024-12-31 |
|     200118 | Parkway, Camden Town               |         9730 | 2024-01-01 | 2024-09-23 |
|     200118 | Albert Street, Camden Town         |          662 | 2024-11-19 | 2025-01-01 |
|     300100 | Limburg Road, Clapham Junction     |         6629 | 2024-01-01 | 2024-12-31 |
|     300100 | Limburg Road, Clapham Junction_OLD |         1674 | 2024-10-01 | 2024-12-10 |

With that information we can conclude that the reason for the name conflicts are:

-   **Station 964**: Input error between May and August of 2024.
-   **Station 1006**: Name change on October of 2024.
-   **Station 200118**: Name change between October and November of 2024.
    -   Possible closure during October, since records with that ID only started to reappear mid-November.
-   **Station 300100**: Input error between October and December of 2024.
    -   We expected the `_OLD` suffix to appear from January to some point mid-year, but alas it didn't.

Since the TfL decided to keep the `station_id` after this changes, we will assume that:

-   `station_id` is a reliable identifier for each station.
-   The name discrepancies don't represent an issue on the reference integrity.
-   Until we extend the dataset with station location (latitude, longitude) data or similar, we can't but assume that the stations did not change it's geographical location during this period.
-   The last seen name will be used when a Station Name is required

Again, we write a query to build a normalized station table.

```sql
EXPLAIN
WITH stations_unique AS (
  SELECT
    station_start_id AS station_id,
    station_start_name AS station_name,
    date_start AS trip_date
  FROM trips_raw
  UNION ALL
  SELECT
    station_end_id AS station_id,
    station_end_name AS station_name,
    date_end AS trip_date
  FROM trips_raw
), stations_complete AS (
    SELECT
        station_start_id AS station_id,
        station_start_name AS station_name,
        date_start AS trip_date
    FROM trips_raw
    UNION ALL
    SELECT
        station_end_id AS station_id,
        station_end_name AS station_name,
        date_end AS trip_date
    FROM trips_raw
), latest_station AS (
    SELECT
        station_id,
        station_name,
        ROW_NUMBER() OVER (
            PARTITION BY station_id
            ORDER BY trip_date DESC
    ) AS rn
    FROM stations_complete
)
SELECT
    station_id,
    station_name
FROM latest_station
WHERE rn = 1
AND station_id IN (
    SELECT station_id
    FROM stations_unique
    GROUP BY station_id
    HAVING COUNT(DISTINCT station_name) > 1
)
ORDER BY station_id;
```

| station_id | station_name                   |
| ---------: | ------------------------------ |
|        964 | Bath Street, St. Luke's        |
|       1006 | Percy Street, Bloomsbury       |
|     200118 | Albert Street, Camden Town     |
|     300100 | Limburg Road, Clapham Junction |

Removing the lines used to filter the conflicting `station_id` we arrive at a query that will result in a normalized stations table.

```sql
WITH stations_complete AS (
    SELECT
        station_start_id AS station_id,
        station_start_name AS station_name,
        date_start AS trip_date
    FROM trips_raw
    UNION ALL
    SELECT
        station_end_id AS station_id,
        station_end_name AS station_name,
        date_end AS trip_date
    FROM trips_raw
), stations_ranked AS (
    SELECT
        station_id,
        station_name,
        ROW_NUMBER() OVER (
            PARTITION BY station_id
            ORDER BY trip_date DESC
    ) AS rn
    FROM stations_complete
)
SELECT
    station_id,
    station_name
FROM stations_ranked
WHERE rn = 1
ORDER BY station_id;
```
