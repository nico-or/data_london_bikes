# Data Extension

To facilitate future analysis, new attributes will be added to the dataset.

## Route ID

To study route data we can create an ID for the route by concatenating the `station_start_id` and `station_end_id` for each trip.

```sql
-- Unidirectional. A-to-B is different from B-to-A
ALTER TABLE trips
ADD COLUMN route_id_directional VARCHAR;

UPDATE trips
SET route_id_directional = CONCAT(station_start_id, '_', station_end_id);

-- Direction agnostic. A-to-B is the same as B-to-A
ALTER TABLE trips
ADD COLUMN route_id_bidirectional VARCHAR;

UPDATE trips
SET route_id_bidirectional = CONCAT(
    LEAST(station_start_id,station_end_id),
    '_',
    GREATEST(station_start_id,station_end_id)
);
```

## Trip duration in minutes

Milliseconds is not the most intuitive time measure unit to work with.
A quick quantile check can tell us which of seconds, minutes or hours is the most appropriate measure.

```sql
SELECT
    CAST(MIN(dm) AS FLOAT) AS min,
    CAST(MAX(dm) AS FLOAT) AS max,
    CAST(AVG(dm) AS FLOAT) AS avg,
    CAST(quantile_disc(dm, 0.25) AS FLOAT) AS q25,
    CAST(quantile_disc(dm, 0.50) AS FLOAT) AS q50,
    CAST(quantile_disc(dm, 0.75) AS FLOAT) AS q75
FROM (
    SELECT duration_ms/(1000 * 60) AS dm
    FROM trips
);
```

|         min |        max |      avg |       q25 |      q50 |       q75 |
| ----------: | ---------: | -------: | --------: | -------: | --------: |
| 0.011316666 | 116181.195 | 23.02052 | 7.6446333 | 13.06195 | 20.923416 |

We see that **75% of the trips last less than 21 minutes**, with a median of 13 minutes.
With this reference we choose minutes as the most representative time measure.

```sql
-- Add trip duration in minutes column
ALTER TABLE trips
ADD COLUMN duration_minutes DOUBLE;

UPDATE trips
SET duration_minutes = duration_ms/(1000 * 60);
```

## Round trip flag

Further inspection of the `trips` table shows that we have both **one-way trips** and **round trips**.

-   **One-way trip:** Starts and ends on different stations.
-   **Round trip:** Starts and ends on different stations

We add a boolean column to quickly filter between round and one-way trips.

```sql
-- Add round trip boolean column
ALTER TABLE trips
ADD COLUMN round_trip BOOL;

UPDATE trips
SET round_trip = (station_start_id == station_end_id);
```
