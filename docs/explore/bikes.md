# Bikes

## Bike IDs

We verify that there are no `NULL` `bike_id`.

```sql
SELECT COUNT(bike_id) as bike_id_null_count
FROM trips_raw
WHERE bike_id IS NULL;
```

| bike_id_null_count |
| -----------------: |
|                  0 |

We check the extremes of the `bike_id` attribute to find weird records.

```sql
SELECT DISTINCT bike_id
FROM trips_raw
ORDER BY bike_id ASC
LIMIT 10;
```

| bike_id |
| ------: |
|       2 |
|       4 |
|       6 |
|       9 |
|   10168 |
|   10169 |
|   10274 |
|   10300 |
|   10307 |
|   10310 |

```sql
SELECT DISTINCT bike_id
FROM trips_raw
ORDER BY bike_id DESC
LIMIT 10;
```

| bike_id |
| ------: |
|   99997 |
|   99993 |
|   99984 |
|   99982 |
|   99975 |
|   63550 |
|   63549 |
|   63548 |
|   63547 |
|   63546 |

We identify Bikes 2, 4, 6, 9, 99975, 99982, 99984, 99993 and 99997 as suspicious, so we proceed to gather some general information and compare it against the other bikes in the dataset.

```sql
SELECT
  bike_id,
  COUNT() AS trip_count,
  strftime(MIN(date_start),'%Y-%m-%d') AS first_seen,
  strftime(MAX(date_end),'%Y-%m-%d') AS  last_seen,
FROM trips_raw
WHERE bike_id NOT IN [2,4,6,9,99997,99993,99984,99982,99975]
GROUP BY bike_id
ORDER BY trip_count DESC
LIMIT 20;
```

| bike_id | trip_count | first_seen | last_seen  |
| ------: | ---------: | ---------- | ---------- |
|       2 |        553 | 2024-01-11 | 2024-12-20 |
|       4 |        579 | 2024-01-02 | 2024-12-31 |
|       6 |        186 | 2024-07-20 | 2024-12-31 |
|       9 |        449 | 2024-05-25 | 2024-12-24 |
|   99975 |          1 | 2024-10-06 | 2024-10-06 |
|   99982 |          1 | 2024-02-08 | 2024-02-08 |
|   99984 |          3 | 2024-05-13 | 2024-12-08 |
|   99993 |          1 | 2024-12-30 | 2024-12-30 |
|   99997 |          1 | 2024-08-19 | 2024-08-19 |

We gather the same information about the least and most used bikes among all the non-suspicious ones.

```sql
SELECT
  bike_id,
  COUNT() AS trip_count,
  strftime(MIN(date_start),'%Y-%m-%d') AS first_seen,
  strftime(MAX(date_end),'%Y-%m-%d') AS  last_seen,
FROM trips_raw
WHERE bike_id NOT IN [2, 4, 6, 9, 99975, 99982, 99984, 99993, 99997]
GROUP BY bike_id
ORDER BY trip_count DESC, bike_id
LIMIT 10;
```

| bike_id | trip_count | first_seen | last_seen  |
| ------: | ---------: | ---------- | ---------- |
|   56472 |       1403 | 2024-01-01 | 2024-12-25 |
|   58857 |       1402 | 2024-01-01 | 2024-12-30 |
|   58920 |       1403 | 2024-01-02 | 2024-12-31 |
|   59410 |       1430 | 2024-01-01 | 2024-12-31 |
|   59455 |       1420 | 2024-01-03 | 2024-12-30 |
|   59610 |       1408 | 2024-01-09 | 2024-12-28 |
|   59633 |       1423 | 2024-01-05 | 2025-01-01 |
|   59688 |       1430 | 2024-01-03 | 2024-12-29 |
|   59751 |       1463 | 2024-01-16 | 2024-12-31 |
|   59882 |       1417 | 2024-01-01 | 2024-12-31 |

```sql
SELECT
  bike_id,
  COUNT() AS trip_count,
  strftime(MIN(date_start),'%Y-%m-%d') AS first_seen,
  strftime(MAX(date_end),'%Y-%m-%d') AS  last_seen,
FROM trips_raw
WHERE bike_id NOT IN [2,4,6,9,99997,99993,99984,99982,99975]
GROUP BY bike_id
ORDER BY trip_count, bike_id
LIMIT 10;
```

| bike_id | trip_count | first_seen | last_seen  |
| ------: | ---------: | ---------- | ---------- |
|   12835 |          1 | 2024-01-01 | 2024-01-01 |
|   21823 |          1 | 2024-01-02 | 2024-01-02 |
|   22232 |          1 | 2024-12-31 | 2024-12-31 |
|   22438 |          1 | 2024-01-05 | 2024-01-05 |
|   22734 |          1 | 2024-12-31 | 2024-12-31 |
|   23085 |          1 | 2024-06-11 | 2024-06-12 |
|   51141 |          1 | 2024-03-13 | 2024-03-13 |
|   60486 |          1 | 2024-01-01 | 2024-01-01 |
|   50166 |          2 | 2024-09-10 | 2024-10-08 |
|   53154 |          2 | 2024-01-03 | 2024-01-03 |

We decided that the suspicious bikes don't have any noticeable difference in behavior whe comparing against the rest of the bikes in the dataset.

## Low trip count bikes

After identifying several bikes with high ID and low trip count, we decided to give a closer look to all bikes with low trip count. However, we did not find any suspicious patterns on their trip duration, stations, date or time. So we decided to not explore further in that direction.

```sql
WITH bids AS (
  SELECT bike_id
  FROM trips_raw
  GROUP BY bike_id
  HAVING COUNT() <= 3
)
SELECT
trip_id,
bike_id,
bike_model,
date_start,
date_end,
station_start_id,
station_end_id,
duration_text
FROM trips_raw
WHERE bike_id IN (SELECT bike_id FROM bids)
ORDER BY date_start;
```

|   trip_id | bike_id | bike_model | date_start          | date_end            | station_start_id | station_end_id | duration_text |
| --------: | ------: | ---------- | ------------------- | ------------------- | ---------------: | -------------: | ------------- |
| 136450452 |   12835 | CLASSIC    | 2024-01-01 00:20:00 | 2024-01-01 00:44:00 |           200039 |            991 | 23m 57s       |
| 136461635 |   60486 | PBSC_EBIKE | 2024-01-01 14:30:00 | 2024-01-01 14:32:00 |             1195 |           1195 | 1m 30s        |
| 136467442 |   21823 | CLASSIC    | 2024-01-02 19:53:00 | 2024-01-02 20:03:00 |           200133 |         200240 | 10m 10s       |
| 136472765 |   53154 | CLASSIC    | 2024-01-03 08:55:00 | 2024-01-03 09:07:00 |             1104 |           1044 | 11m 24s       |
| 136479867 |   53154 | CLASSIC    | 2024-01-03 17:31:00 | 2024-01-03 17:44:00 |             1049 |           1100 | 13m 8s        |
| 136499834 |   22438 | CLASSIC    | 2024-01-05 08:37:00 | 2024-01-05 08:55:00 |             1115 |         200096 | 17m 47s       |
| 137177798 |   99982 | CLASSIC    | 2024-02-08 10:25:00 | 2024-02-08 10:28:00 |             1221 |           1034 | 3m 25s        |
| 137840860 |   51141 | CLASSIC    | 2024-03-13 07:45:00 | 2024-03-13 08:03:00 |           300031 |           1164 | 18m 22s       |
| 139296798 |   99984 | CLASSIC    | 2024-05-13 09:04:00 | 2024-05-13 09:04:00 |             2692 |           2692 | 26s           |
| 140101668 |   23085 | CLASSIC    | 2024-06-11 12:48:00 | 2024-06-12 10:46:00 |            22181 |          22181 | 21h 58m 19s   |
| 140952329 |   62812 | PBSC_EBIKE | 2024-07-10 17:20:00 | 2024-07-10 17:34:00 |            10624 |           1087 | 13m 29s       |
| 140953497 |   62812 | PBSC_EBIKE | 2024-07-10 17:38:00 | 2024-07-10 17:53:00 |             1087 |           1162 | 14m 10s       |
| 142176513 |   99997 | CLASSIC    | 2024-08-19 13:37:00 | 2024-08-19 13:43:00 |             1027 |           3423 | 5m 46s        |
| 142771136 |   50166 | CLASSIC    | 2024-09-10 14:45:00 | 2024-09-10 14:55:00 |           300211 |           1079 | 9m 41s        |
| 143477154 |   99975 | CLASSIC    | 2024-10-06 14:08:00 | 2024-10-06 14:14:00 |             2682 |           1041 | 6m 12s        |
| 143524599 |   50166 | CLASSIC    | 2024-10-08 10:56:00 | 2024-10-08 11:01:00 |           300081 |         300024 | 5m 23s        |
| 143576758 |   99984 | CLASSIC    | 2024-10-10 08:17:00 | 2024-10-10 08:31:00 |           300069 |           1107 | 14m 38s       |
| 145040410 |   99984 | CLASSIC    | 2024-12-06 14:06:00 | 2024-12-08 09:07:00 |             1200 |           3469 | 1d 19h 0m 30s |
| 145309013 |   63496 | PBSC_EBIKE | 2024-12-20 07:33:00 | 2024-12-20 07:55:00 |           200023 |         300237 | 21m 14s       |
| 145313862 |   63496 | PBSC_EBIKE | 2024-12-20 11:59:00 | 2024-12-20 12:16:00 |           300237 |           2683 | 17m 29s       |
| 145315365 |   63496 | PBSC_EBIKE | 2024-12-20 13:18:00 | 2024-12-20 13:38:00 |             2683 |          22171 | 20m 4s        |
| 145330628 |   30114 | CLASSIC    | 2024-12-21 15:52:00 | 2024-12-21 16:12:00 |             2636 |           2633 | 19m 52s       |
| 145334391 |   30114 | CLASSIC    | 2024-12-21 21:24:00 | 2024-12-21 21:29:00 |             2633 |           1143 | 4m 56s        |
| 145362698 |   41547 | CLASSIC    | 2024-12-24 16:26:00 | 2024-12-24 16:29:00 |           300070 |         300075 | 3m 6s         |
| 145365262 |   30114 | CLASSIC    | 2024-12-24 23:08:00 | 2024-12-24 23:16:00 |             1143 |         300088 | 8m 23s        |
| 145380843 |   41547 | CLASSIC    | 2024-12-25 16:53:00 | 2024-12-25 17:26:00 |           300075 |         300075 | 33m 2s        |
| 145425814 |   41547 | CLASSIC    | 2024-12-30 09:12:00 | 2024-12-30 09:51:00 |           300075 |         200212 | 38m 14s       |
| 145434689 |   99993 | CLASSIC    | 2024-12-30 19:02:00 | 2024-12-30 19:04:00 |           300224 |         300224 | 1m 30s        |
| 145445352 |   22734 | CLASSIC    | 2024-12-31 16:23:00 | 2024-12-31 16:34:00 |             2694 |         200183 | 11m 46s       |
| 145448676 |   22232 | CLASSIC    | 2024-12-31 21:37:00 | 2024-12-31 21:50:00 |           300207 |          10628 | 13m 9s        |
