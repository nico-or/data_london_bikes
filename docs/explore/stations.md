# Stations

## \_OLD Stations

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
