# Data Gathering

The data source is the [Transport for London (TfL) Open Data](https://tfl.gov.uk/info-for/open-data-users/our-open-data), in particular, their [cycling section](https://cycling.data.tfl.gov.uk/).

The data is published aggregating 2 weeks of data per CSV file (2 per month, 24 in a year).

## Download

Opening the [TfL cycling repositorty](https://cycling.data.tfl.gov.uk/) and executing the following script on the browser console will return an array with the desired 24 elements. After that, one could use many methods to actually download the CSV files.

```js
links = $$("a");
links.filter((e) => e.innerText.includes("2024.csv"));
```

To save disk space we compress eeach individual file using gzip.

```sh
ls data/*.csv | parallel -j 6 gzip -k {}
```

This reduces the dataset size from 1.4Gb to 300Mb.
