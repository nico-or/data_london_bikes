# Exploration

With our data loaded into a SQL database we can perform some basic sanity checks on it's record.

We find that there are no records with `NULL` identifiers.

## Bikes

### Bike IDs

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

### Low trip count bikes

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

## Dates

### NULL Start or End Date

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

### Date ranges

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

## Trip Duration

### Distribution

We check the range and distribution of the time duration. We use minutes to get more meaningful numbers.

```sql
SELECT
    ROUND(MIN(dm), 2) AS min,
    ROUND(MAX(dm), 2) AS max,
    ROUND(AVG(dm), 2) AS avg,
    ROUND(quantile_disc(dm, 0.25), 2) AS q25,
    ROUND(quantile_disc(dm, 0.50), 2) AS q50,
    ROUND(quantile_disc(dm, 0.75), 2) AS q75
FROM (
    SELECT duration_ms/(1000 * 60) AS dm
    FROM trips_raw
);
```

|  min |      max |   avg |  q25 |   q50 |   q75 |
| ---: | -------: | ----: | ---: | ----: | ----: |
| 0.01 | 116181.2 | 23.02 | 7.64 | 13.06 | 20.92 |

We see that the distribution is **heavily skewed** towards the left. With most trips taking less than 21 minutes, but the longest ones taking multiple days.

The minimum value is close to 0, our hypothesis being that those records are people:

-   testing or demo-ing how to use the system.
-   putting it back right after picking it up, either by mistake or because they changed their minds.

The maximum value of 116181 minutes correspond to a total of about 80 days. We assume this and many other records correspond to people taking the bikes home, or the bike return not being registered in the stations.

In any case, we will have to take into account the duration distribution when cleaning and extending the data, by either dropping certain the values or classifying them according to their duration.

## Stations

### \_OLD Stations

While exploring the dataset, we found many stations with a name suffixed with `_OLD`.

```sql
WITH
stations AS (
  SELECT
    station_start_id AS station_id,
    station_start_name AS station_name,
  FROM trips_raw
  UNION ALL
  SELECT
    station_end_id AS station_id,
    station_end_name AS station_name,
  FROM trips_raw
)
SELECT
  station_id,
  station_name
FROM stations
WHERE contains(station_name, '_OLD')
GROUP BY station_id, station_name
ORDER BY station_id;
```

| station_id | station_name                              |
| ---------: | ----------------------------------------- |
|     300100 | Limburg Road, Clapham Junction_OLD        |
|    1020444 | Leonard Circus , Shoreditch_OLD           |
|    1059444 | Albert Embankment, Vauxhall_OLD           |
|    1190444 | Kennington Lane Rail Bridge, Vauxhall_OLD |
|    3429444 | Abbey Orchard Street, Westminster_OLD     |
|  200032444 | Kennington Oval, Oval_OLD                 |
|  200083444 | Pritchard's Road, Bethnal Green_OLD       |

Further exploration revealed that the ID of those stations correlates to other Stations but with a suffixed `444`.

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
WHERE station_id IN [
  300100,
  1020, 1020444,
  1059, 1059444,
  1190, 1190444,
  3429, 3429444,
  200032, 200032444,
  200083, 200083444
]
GROUP BY station_id, station_name
ORDER BY station_name, first_seen;
```

| station_id | station_name                              | record_count | first_seen | last_seen  |
| ---------: | ----------------------------------------- | -----------: | ---------- | ---------- |
|       3429 | Abbey Orchard Street, Westminster         |        15124 | 2024-01-01 | 2024-12-31 |
|    3429444 | Abbey Orchard Street, Westminster_OLD     |         8288 | 2024-05-01 | 2024-08-15 |
|       1059 | Albert Embankment, Vauxhall               |        12473 | 2024-01-01 | 2024-09-30 |
|    1059444 | Albert Embankment, Vauxhall_OLD           |         3569 | 2024-10-01 | 2024-12-31 |
|       1190 | Kennington Lane Rail Bridge, Vauxhall     |        32427 | 2024-01-01 | 2024-09-30 |
|    1190444 | Kennington Lane Rail Bridge, Vauxhall_OLD |        10531 | 2024-10-01 | 2024-12-31 |
|     200032 | Kennington Oval, Oval                     |        17686 | 2024-01-01 | 2024-12-31 |
|  200032444 | Kennington Oval, Oval_OLD                 |          356 | 2024-05-20 | 2024-06-02 |
|       1020 | Leonard Circus , Shoreditch               |        20949 | 2024-01-01 | 2025-01-01 |
|    1020444 | Leonard Circus , Shoreditch_OLD           |        11873 | 2024-05-01 | 2024-08-16 |
|     300100 | Limburg Road, Clapham Junction            |         6803 | 2024-01-01 | 2024-12-31 |
|     300100 | Limburg Road, Clapham Junction_OLD        |         1710 | 2024-10-01 | 2024-12-10 |
|     200083 | Pritchard's Road, Bethnal Green           |        17595 | 2024-01-01 | 2024-09-30 |
|  200083444 | Pritchard's Road, Bethnal Green_OLD       |         2462 | 2024-10-01 | 2024-12-31 |

We now need to verify where the `_OLD` stations come from. To do so we add an additional dimension to the query, the original `filename` and use it to further divide the results.

```sql
WITH
stations AS (
  SELECT
    station_start_id AS station_id,
    station_start_name AS station_name,
    date_start AS trip_date,
    filename
  FROM trips_raw
  UNION ALL
  SELECT
    station_end_id AS station_id,
    station_end_name AS station_name,
    date_end AS trip_date,
    filename
  FROM trips_raw
)
SELECT
  station_id,
  station_name,
  COUNT(*) AS record_count,
  strftime(MIN(trip_date),'%Y-%m-%d') AS first_seen,
  strftime(MAX(trip_date),'%Y-%m-%d') AS  last_seen,
  filename,
FROM stations
WHERE station_id IN [3429, 3429444]
GROUP BY station_id, station_name, filename
ORDER BY first_seen;
```

Here we present the results for a single station for brevity, but every other pair of stations shares the same behaviour:

-   There is no overlap between the regular and `_OLD` stations.
-   The `_OLD` suffix only appears during a time period, either mid-year or at the end of the year.

| station_id | station_name                          | record_count | first_seen | last_seen  | filename                                                      |
| ---------: | ------------------------------------- | -----------: | ---------- | ---------- | ------------------------------------------------------------- |
|       3429 | Abbey Orchard Street, Westminster     |          500 | 2024-01-01 | 2024-01-14 | data/format_0/387JourneyDataExtract01Jan2024-14Jan2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |         1099 | 2024-01-15 | 2024-01-31 | data/format_0/388JourneyDataExtract15Jan2024-31Jan2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          759 | 2024-02-01 | 2024-02-14 | data/format_0/389JourneyDataExtract01Feb2024-14Feb2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          785 | 2024-02-15 | 2024-02-29 | data/format_0/390JourneyDataExtract15Feb2024-29Feb2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          887 | 2024-03-01 | 2024-03-14 | data/format_0/391JourneyDataExtract01Mar2024-14Mar2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          917 | 2024-03-15 | 2024-03-31 | data/format_0/392JourneyDataExtract15Mar2024-31Mar2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          797 | 2024-04-01 | 2024-04-14 | data/format_0/393JourneyDataExtract01Apr2024-14Apr2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |         1072 | 2024-04-15 | 2024-04-30 | data/format_0/394JourneyDataExtract15Apr2024-30Apr2024.csv.gz |
|    3429444 | Abbey Orchard Street, Westminster_OLD |         1011 | 2024-05-01 | 2024-05-14 | data/format_0/395JourneyDataExtract01May2024-14May2024.csv.gz |
|    3429444 | Abbey Orchard Street, Westminster_OLD |         1258 | 2024-05-15 | 2024-05-31 | data/format_0/396JourneyDataExtract15May2024-31May2024.csv.gz |
|    3429444 | Abbey Orchard Street, Westminster_OLD |         1020 | 2024-06-01 | 2024-06-14 | data/format_0/397JourneyDataExtract01Jun2024-14Jun2024.csv.gz |
|    3429444 | Abbey Orchard Street, Westminster_OLD |         1264 | 2024-06-15 | 2024-07-08 | data/format_0/398JourneyDataExtract15Jun2024-30Jun2024.csv.gz |
|    3429444 | Abbey Orchard Street, Westminster_OLD |         1208 | 2024-07-01 | 2024-07-14 | data/format_0/399JourneyDataExtract01Jul2024-14Jul2024.csv.gz |
|    3429444 | Abbey Orchard Street, Westminster_OLD |         1444 | 2024-07-15 | 2024-08-02 | data/format_0/400JourneyDataExtract15Jul2024-31Jul2024.csv.gz |
|    3429444 | Abbey Orchard Street, Westminster_OLD |         1072 | 2024-08-01 | 2024-08-14 | data/format_1/401JourneyDataExtract01Aug2024-14Aug2024.csv.gz |
|    3429444 | Abbey Orchard Street, Westminster_OLD |           11 | 2024-08-15 | 2024-08-15 | data/format_1/402JourneyDataExtract15Aug2024-26Aug2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          204 | 2024-08-21 | 2024-08-26 | data/format_1/402JourneyDataExtract15Aug2024-26Aug2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |            1 | 2024-08-22 | 2024-08-22 | data/format_1/401JourneyDataExtract01Aug2024-14Aug2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |         1633 | 2024-08-27 | 2024-09-17 | data/format_1/403JourneyDataExtract27Aug2024-17Sep2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          833 | 2024-09-18 | 2024-09-30 | data/format_1/404JourneyDataExtract18Sep2024-30Sep2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          999 | 2024-10-01 | 2024-11-21 | data/format_0/405JourneyDataExtract01Oct2024-14Oct2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |         1411 | 2024-10-15 | 2024-10-31 | data/format_0/406JourneyDataExtract15Oct2024-31Oct2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |         1062 | 2024-11-01 | 2024-11-14 | data/format_0/407JourneyDataExtract01Nov2024-14Nov2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          778 | 2024-11-15 | 2024-12-02 | data/format_0/408JourneyDataExtract15Nov2024-30Nov2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          792 | 2024-12-01 | 2024-12-14 | data/format_0/409JourneyDataExtract01Dec2024-14Dec2024.csv.gz |
|       3429 | Abbey Orchard Street, Westminster     |          595 | 2024-12-15 | 2024-12-31 | data/format_0/410JourneyDataExtract15Dec2024-31Dec2024.csv.gz |

Since we found no documentation on the TfL website addressing this issue, we can only speculate about the reason for the change. We assume that during these time windows, the stations were temporarily relocated due to factors such as street remodeling or major construction work.

Because we lack additional information about this decision, and given that there are many \_OLD station records while the regular stations are missing data for several months, we decided to consolidate all \_OLD station records into the corresponding regular stations. This allows us to maintain a continuous usage history for each station.

For example, `3429444 | Abbey Orchard Street, Westminster_OLD` will become `3429 | Abbey Orchard Street, Westminster`.

## Station format

Station Names seem to follow the pattern `location, area`, both of which could become a calculated field later. We verify that all stations follow this pattern using regex.

```sql
WITH
stations AS (
  SELECT
    station_start_id AS station_id,
    station_start_name AS station_name
  FROM trips_raw
  UNION
  SELECT
    station_end_id AS station_id,
    station_end_name AS station_name
  FROM trips_raw
)
SELECT
station_id,
station_name
FROM stations
WHERE NOT regexp_matches(station_name, '^[^,]+\s*,\s*[^,]+$')
GROUP BY station_id, station_name
ORDER BY station_id;
```

| station_id | station_name                                |
| ---------: | ------------------------------------------- |
|      10626 | Mechanical Workshop Penton                  |
|      22168 | Mechanical Workshop Clapham                 |
|     200175 | Wandsworth Rd, Isley Court, Wandsworth Road |
|     300245 | Clapham Road, Lingham Street, Stockwell     |

We found that 4 stations don't follow the pattern:

-   Both _Mechanical Workshop_ stations don't have a comma and are most likely used as internal locations.
-   The other two stations have 2 commas, so we must be careful when splitting the `station_name` in the future.

## Workshop Stations

We check the trips starting and ending on the two _workshop stations_ found previously, to decide if these area real stations or internal ones.

```sql
SELECT COUNT() AS trip_count
FROM trips_raw
WHERE station_start_id IN [10626, 22168];
```

| trip_count |
| ---------: |
|          4 |

```sql
SELECT COUNT() AS trip_count
FROM trips_raw
WHERE station_end_id IN [10626, 22168];
```

| trip_count |
| ---------: |
|        428 |

Our suspicion is confirmed by the large imbalance between trips starting and ending on both stations.

Since these stations aren't part of the bike network they should be dropped on the cleaning phase.
