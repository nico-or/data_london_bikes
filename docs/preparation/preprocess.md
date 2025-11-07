# Data Pre Processing

Before analysis we must join all files into a convenient format that allows us freedom to query and transform the data. The tool of choice was DuckDB.

DuckDB allows us to:

- fast iteration while working on the CLI
- load csv data from zipped csv files
- export the data to multiple file formats such as duckdb, sqlite, csv and more.
- execute SQL queries stored in plaintext files against said database

## Attribute renaming

New values for the trip attributes is assigned at load time to simplify SQL query writting.

| Original Field Name  | New Field Name     | DuckDB type |
| -------------------- | ------------------ | ----------- |
| Number               | trip_id            | BIGINT      |
| Start date           | date_start         | TIMESTAMP   |
| Start station number | station_start_id   | BIGINT      |
| Start station        | station_start_name | VARCHAR     |
| End date             | date_end           | TIMESTAMP   |
| End station number   | station_end_id     | BIGINT      |
| End station          | station_end_name   | VARCHAR     |
| Bike number          | bike_id            | BIGINT      |
| Bike model           | bike_model         | VARCHAR     |
| Total duration       | duration_text      | VARCHAR     |
| Total duration (ms)  | duration_ms        | BIGINT      |

The SQL command to create the table

```sql
-- Create target table
CREATE TABLE trips_raw (
    trip_id BIGINT,
    date_start TIMESTAMP,
    date_end TIMESTAMP,
    station_start_id BIGINT,
    station_end_id BIGINT,
    station_start_name VARCHAR,
    station_end_name VARCHAR,
    bike_id BIGINT,
    bike_model VARCHAR,
    duration_text VARCHAR,
    duration_ms BIGINT,
);
```

## CSV formatting

There are 2 types of formatting between the 24 files, the 4 files from August and September beign the only odd ones.

The main format:

- quotes on every field
- 0-padded strings as IDs for Trips, Stations and Bikes
- Timestamp format is `YYYY-MM-DD HH:MM`

```
"Number"   , "Start date"      , "Start station number", "Start station"                       , "End date"        , "End station number", "End station"                        , "Bike number", "Bike model", "Total duration", "Total duration (ms)"
"136666627", "2024-01-14 23:59", "001108"              , "North Wharf Road, Paddington"        , "2024-01-15 00:06", "003423"            , "Maida Vale, Maida Vale"             , "53020"      , "CLASSIC"   , "6m 47s"        , "407799"
"136666625", "2024-01-14 23:57", "003447"              , "Gloucester Road (North), Kensington" , "2024-01-15 00:05", "001214"            , "Kensington Olympia Station, Olympia", "54559"      , "CLASSIC"   , "8m 1s"         , "481276"
```

The secondary format:

- quotes only on station name fields
- non-0-padded integers as IDs for Trips, Staations and Bikes
- Timestamp format is `DD/MM/YYYY HH:MM`

```
Number   , Start date      , Start station number, Start station                        , End date        , End station number, End station                       , Bike number, Bike model, Total duration, Total duration (ms)
142043054, 14/08/2024 23:59,                22165, "Fisherman's Walk West, Canary Wharf", 15/08/2024 00:40,             200233, "South Quay East, Canary Wharf"   ,       59663, CLASSIC   , 40m 53s       ,             2453526
142043055, 14/08/2024 23:59,                22159, "Ebury Bridge, Pimlico"              , 15/08/2024 00:04,                965, "Tachbrook Street, Victoria"      ,       57811, CLASSIC   , 4m 54s        ,              294201
```

## Data Load

After accounting for the attributes data types, name aliases and timestamp formatting differences, we arrive at 2 SQL statements to load the data.

A reduced version of the final query to load the secondary format files:

```sql
-- Load format_1 files
INSERT INTO trips_raw
SELECT
    "Number" AS trip_id,
    -- more lines ...
    "Total duration (ms)" AS duration_ms,
FROM read_csv(
    'data/format_1/*.csv.gz',
    types={
        'Start date': TIMESTAMP,
        -- more lines ...
        'Bike number': BIGINT,
    },
    timestampformat='%d/%m/%Y %H:%M'
);
```

## Utility Attributes

To facilitate future analysis a few new atttributes will be created.

### Route ID

To create a `route_id` we concatenate the 0-padded versions of the station IDs. After checking the maximun value of a station ID, 9 characters are enough to pad every value.

```sql
ALTER TABLE trips_raw
ADD COLUMN route_id VARCHAR;

UPDATE trips_raw
SET route_id = format('{:09d}{:09d}', station_start_id, station_end_id);
```

Using this scheme also ensures that the route from A to B is different from the route from B to A.

### Trip duration in minutes

A quick check of the `duration_ms` attribute reveals that 75% of the values fall bellow 21 minutes.

```sql
SUMMARIZE -- DuckDb utility function
SELECT duration_ms/(1000 * 60)
FROM trips_raw;

-- Q25:  7.64 minutes
-- Q50: 13.05 minutes
-- Q75: 20.92 minutes
```

With this reference values I decided to add a calculated duration_minutes attribute to each record to facilitate filtering.

```sql
ALTER TABLE trips_raw
ADD COLUMN duration_minutes DOUBLE;

UPDATE trips_raw
SET duration_minutes = duration_ms/(1000 * 60);
```

### Round trip flag

A boolean column is added to quickly filter trips that start and end in the same location.

```sql
-- Add round trip flag
ALTER TABLE trips
ADD COLUMN round_trip BOOL DEFAULT false;

UPDATE trips
SET round_trip = (station_start_id == station_end_id);
```
