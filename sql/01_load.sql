-- Load gzipped csv files into a DuckDB table

-- Create target table
CREATE OR REPLACE TABLE trips_raw (
    trip_id BIGINT,
    date_start DATETIME,
    date_end DATETIME,
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

-- Load format_0 files
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
        filename,
    FROM read_csv(
        'data/format_0/*.csv.gz',
        types={
            'Start date': TIMESTAMP,
            'Start station number': BIGINT,
            'End station number': BIGINT,
            'Number': BIGINT,
            'Bike number': BIGINT,
        },
        filename=true
    );

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
        filename,
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