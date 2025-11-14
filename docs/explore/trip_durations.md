# Trip Duration

## Distribution

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
