# Normalization

Having decided on a data model and checked the reference integrity of `bike_id` and `station_id` we can execute the normalization of the `trips_raw` table.

We start by extracting the tables that don't have foreign keys. Most of the logic as described in the _Data Validation_ section.

## Bikes

We take all unique `bike_id` from `trips_raw` and choose the last recorded `bike_model`.

```sql
CREATE TABLE bikes (
    bike_id UBIGINT PRIMARY KEY,
    model TEXT
);

INSERT INTO bikes (bike_id, model)
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
WHERE rn = 1;

CREATE INDEX bike_id_idx ON bikes (bike_id);
```

## Stations

We take all unique `station_id` from `trips_raw` and choose the last recorded `station_name`.

```sql
CREATE TABLE stations (
    station_id UBIGINT PRIMARY KEY,
    station_name TEXT
);

INSERT INTO stations (station_id, station_name)
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
WHERE rn = 1;

CREATE INDEX station_id_idx ON stations (station_id);
```

## Trips

For the trips table, simply selecting all attributes except for both `station_*_name` and `bike_model` will suffice. We will also drop the `duration_text` attribute since it does not provide analysis utility and can easily be regenerated on demand.

```sql
CREATE TABLE trips (
    trip_id UBIGINT PRIMARY KEY,
    date_start DATETIME,
    date_end DATETIME,
    bike_id UBIGINT,
    station_start_id UBIGINT,
    station_end_id UBIGINT,
    duration_ms UBIGINT,
    FOREIGN KEY (bike_id) REFERENCES bikes(bike_id),
    FOREIGN KEY (station_start_id) REFERENCES stations(station_id),
    FOREIGN KEY (station_end_id) REFERENCES stations(station_id),
);


INSERT INTO trips
SELECT
    trip_id,
    date_start,
    date_end,
    bike_id,
    station_start_id,
    station_end_id,
    duration_ms
FROM trips_raw;

CREATE INDEX trip_id_idx ON trips (trip_id);
```
