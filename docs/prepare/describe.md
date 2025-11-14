# Describe

## Schema

Every record in the dataset has the following fields:

| Field                | Data Type | Role      | Description                                          |
| -------------------- | --------- | --------- | ---------------------------------------------------- |
| Number               | UINT      | PK        | Record ID                                            |
| Start date           | TIMESTAMP | Attribute | Start of trip timestamp                              |
| Start station number | UINT      | FK        | Start station ID                                     |
| Start station        | STRING    | Attribute | Name of start station                                |
| End date             | TIMESTAMP | Attribute | End of trip timestamp                                |
| End station number   | UINT      | FK        | End station ID                                       |
| End station          | STRING    | Attribute | Name of end station                                  |
| Bike number          | UINT      | FK        | Bike ID                                              |
| Bike model           | STRING    | Attribute | Type of bike                                         |
| Total duration       | STRING    | Attribute | Human-readable representation of Total duration (ms) |
| Total duration (ms)  | UINT      | Attribute | Bike trip length in milliseconds                     |
