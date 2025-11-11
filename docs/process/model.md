# Data Modeling

Applying data modeling and database normalization will provide a more manageable database and some principles to make it internally coherent.

## Entities

A quick inspection of the original record attributes makes it obvious that it's merging attributes from 3 entities into individual records. We can easily normalize our `trips_raw` table into `trips`, `stations`and `bikes`.

| Attribute          | Entity  |
| ------------------ | ------- |
| trip_id            | Trip    |
| date_start         | Trip    |
| station_start_id   | Station |
| station_start_name | Station |
| date_end           | Trip    |
| station_end_id     | Station |
| station_end_name   | Station |
| bike_id            | Bike    |
| bike_model         | Bike    |
| duration_text      | Trip    |
| duration_ms        | Trip    |

Resulting in the following Entity Relationship diagram:

![Entity Relationship diagram.](../images/mermaid/01_er.svg)

## Date and Time dimensions

We could build a Date and even a Time dimension table to allow better slicing of the dataset. Here an example with the Bike and Stations table omitted for brevity.

![Entity Relationship diagram with Time and Date dimension tables.](../images/mermaid/01_er_time_date_table.svg)

To avoid premature normalization we won't perform this step until we see a clear need for it. We will use Date and Time functions on the queries as the need arise.
