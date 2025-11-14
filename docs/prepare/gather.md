# Gather

The data source is the [Transport for London (TfL) Open Data](https://tfl.gov.uk/info-for/open-data-users/our-open-data), in particular, their [cycling section](https://cycling.data.tfl.gov.uk/).

We will focus on the data presented in the ` usage-stats/` section.

## Available data

The data is published as a single CSV file every two weeks. Individual links for the CSV files ranging from January 2016 up to May 2025 are available at the time of writting. There are also individual ZIP files with all the year CSV files for 2012 to 2016.

We will focus our work on the data from 2024, since it is the most recent year with it's complete data available.

## Download

Opening the [TfL cycling repository](https://cycling.data.tfl.gov.uk/) and executing the following script on the browser console will return an array with the desired 24 elements. After that, one could use many methods to actually download the CSV files.

```js
links = $$("a");
links.filter((e) => {
    e.innerText.includes("2024.csv");
});
```

## Storage

For long time storage we compress the files using Gzip, which reduces the dataset total disk space from 1.4 Gb to 300 Mb.

```sh
# Plain bash
for file in data/*.csv;
do gzip $file;
done

# leveraging GNU parallel
ls data/*.csv | parallel -j 6 gzip {}
```
