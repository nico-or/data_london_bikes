# Data Loading

To allow a more flexible data exploration we must first join the records from the individual CSV files into a single database.

## Attribute renaming

To simplify the SQL query writing we assign new names for the attributes is assigned at load time to simplify SQL query writing.

| Original Attribute Name | New Attribute Name | DuckDB type |
| ----------------------- | ------------------ | ----------- |
| Number                  | trip_id            | BIGINT      |
| Start date              | date_start         | TIMESTAMP   |
| Start station number    | station_start_id   | BIGINT      |
| Start station           | station_start_name | VARCHAR     |
| End date                | date_end           | TIMESTAMP   |
| End station number      | station_end_id     | BIGINT      |
| End station             | station_end_name   | VARCHAR     |
| Bike number             | bike_id            | BIGINT      |
| Bike model              | bike_model         | VARCHAR     |
| Total duration          | duration_text      | VARCHAR     |
| Total duration (ms)     | duration_ms        | BIGINT      |

The SQL command to create the table:

```sql
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
    filename VARCHAR
);
```

## CSV attribute formatting

After inspecting all the CSV files, we found that there are 2 types of formatting. The 4 files from August and September being the only odd ones.

The main format:

-   quotes on every field
-   0-padded strings as IDs for Trips, Stations and Bikes
-   Timestamp format is `YYYY-MM-DD HH:MM`

| "Number"    | "Start date"       | "Start station number" | "Start station"                       | "End date"         | "End station number" | "End station"                         | "Bike number" | "Bike model" | "Total duration" | "Total duration (ms)" |
| ----------- | ------------------ | ---------------------- | ------------------------------------- | ------------------ | -------------------- | ------------------------------------- | ------------- | ------------ | ---------------- | --------------------- |
| "136666627" | "2024-01-14 23:59" | "001108"               | "North Wharf Road, Paddington"        | "2024-01-15 00:06" | "003423"             | "Maida Vale, Maida Vale"              | "53020"       | "CLASSIC"    | "6m 47s"         | "407799"              |
| "136666625" | "2024-01-14 23:57" | "003447"               | "Gloucester Road (North), Kensington" | "2024-01-15 00:05" | "001214"             | "Kensington Olympia Station, Olympia" | "54559"       | "CLASSIC"    | "8m 1s"          | "481276"              |

The secondary format:

-   quotes only on station name fields
-   non-0-padded integers as IDs for Trips, Stations and Bikes
-   Timestamp format is `DD/MM/YYYY HH:MM`

| Number    | Start date       | Start station number | Start station                        | End date         | End station number | End station                     | Bike number | Bike model | Total duration | Total duration (ms) |
| --------- | ---------------- | -------------------- | ------------------------------------ | ---------------- | ------------------ | ------------------------------- | ----------- | ---------- | -------------- | ------------------- |
| 142043054 | 14/08/2024 23:59 | 22165                | "Fisherman's Walk West,Canary Wharf" | 15/08/2024 00:40 | 200233             | "South Quay East, Canary Wharf" | 59663       | CLASSIC    | 40m 53s        | 2453526             |
| 142043055 | 14/08/2024 23:59 | 22159                | "Ebury Bridge, Pimlico"              | 15/08/2024 00:04 | 965                | "Tachbrook Street, Victoria"    | 57811       | CLASSIC    | 4m 54s         | 294201              |

## Data Load

Now we write a DuckDB query that will read evert CSV file, apply the new naming scheme, parse the conflicting timestamp formats and append the records to our `trips_raw` table.

Here is the query to import the secondary format files. The query from the main format remains differs only in the path and `timestampformat` flag.

```sql
-- Load format_1 files
INSERT INTO trips_raw
    SELECT
        "Number" AS trip_id,
        "Start date" AS date_start,
        "End date" AS date_end,
        "Start station number" AS station_start_id,
        "End station number" AS station_end_id,
        "Start station" AS station_start_name,
        "End station" AS station_end_name,
        "Bike number" AS bike_id,
        "Bike model" AS bike_model,
        "Total duration" AS duration_text,
        "Total duration (ms)" AS duration_ms,
        filename
    FROM read_csv(
        'data/format_1/*.csv.gz',
        types={
            'Start date': TIMESTAMP,
            'Start station number': BIGINT,
            'End station number': BIGINT,
            'Number': BIGINT,
            'Bike number': BIGINT,
        },
        filename=true,
        timestampformat='%d/%m/%Y %H:%M'
    );
```
