CREATE TEMP FUNCTION udf_aggregate_json_sum(histograms ARRAY<STRING>) AS (
  ARRAY(
    SELECT AS STRUCT
      FORMAT('%d', values_entry.key) AS key,
      SUM(values_entry.value) AS value
    FROM
      UNNEST(histograms) AS histogram,
      UNNEST(mozfun.hist.extract(histogram).values) AS values_entry
    WHERE
      histogram IS NOT NULL
    GROUP BY
      values_entry.key
    ORDER BY
      values_entry.key
  )
);
CREATE TEMP FUNCTION udf_get_buckets(min INT64, max INT64, num INT64, metric_type STRING)
RETURNS ARRAY<INT64> AS (
  (
    WITH buckets AS (
      SELECT
        CASE
          WHEN metric_type = 'histogram-exponential'
          THEN mozfun.glam.histogram_generate_exponential_buckets(min, max, num)
          ELSE mozfun.glam.histogram_generate_linear_buckets(min, max, num)
       END AS arr
    )

    SELECT ARRAY_AGG(CAST(item AS INT64))
    FROM buckets
    CROSS JOIN UNNEST(arr) AS item
  )
);
WITH per_build_client_day AS (
  SELECT
                *,
                SPLIT(application.version, '.')[OFFSET(0)] AS app_version,
                DATE(submission_timestamp) AS submission_date,
                normalized_os AS os,
                application.build_id AS app_build_id,
                normalized_channel AS channel,
               ARRAY<
                STRUCT<
                    name STRING,
                    metric_type STRING,
                    process STRING,
                    value ARRAY<STRUCT<key STRING, value STRING>>,
                    bucket_range STRUCT<first_bucket INT64, last_bucket INT64, num_buckets INT64>
                >
                >[
      (
        '{{metric}}',
        'histogram-{{metric type}}',
        '{{process}}',
        {{probe location}},
        ({{first_bucket}}, {{last_bucket}}, {{num_buckets}})
      )
                ] AS metrics
  FROM   `moz-fx-data-shared-prod.telemetry_stable.main_v4`
  WHERE
    normalized_channel = '{{channel}}'
    --AND normalized_os="Windows" -- To add OS filter.
    AND application.build_id > FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE, INTERVAL 14 DAY))
    AND application.build_id <= FORMAT_DATE("%Y%m%d", CURRENT_DATE)
    AND DATE(submission_timestamp) >= DATE_SUB(CURRENT_DATE, INTERVAL 14 DAY)
    AND DATE(submission_timestamp) <= CURRENT_DATE
),

filtered_aggregates AS (
  SELECT
    submission_date,
    sample_id,
    client_id,
    os,
    CAST(app_version AS INT) app_version,
    app_build_id,
    channel,
    metrics.name AS metric,
    metrics.metric_type AS metric_type,
    process,
    bucket_range,
    value.key AS key,
    value.value AS value
  FROM
    per_build_client_day
  CROSS JOIN
    UNNEST(metrics) AS metrics
  CROSS JOIN
    UNNEST(metrics.value) AS value
  WHERE
    value IS NOT NULL
),
aggregated AS (
  SELECT
    sample_id,
    client_id,
    submission_date,
    os,
    app_version,
    app_build_id,
    channel,
    metric,
    metric_type,
    process,
    key,
    ARRAY_AGG(bucket_range) AS bucket_range,
    ARRAY_AGG(value) AS value
  FROM
    filtered_aggregates
  GROUP BY
    sample_id,
    client_id,
    submission_date,
    os,
    app_version,
    app_build_id,
    channel,
    process,
    metric,
    metric_type,
    key
),
intermediate_histogram AS (SELECT
  sample_id,
  client_id,
  submission_date,
  os,
  app_version,
  app_build_id,
  aggregated.channel,
  ARRAY_AGG(
     STRUCT<
      metric STRING,
      metric_type STRING,
      key STRING,
      process STRING,
      agg_type STRING,
      bucket_range STRUCT<first_bucket INT64, last_bucket INT64, num_buckets INT64>,
      value ARRAY<STRUCT<key STRING, value INT64>>
    >(
      metric,
      metric_type,
      key,
      process,
      'summed_histogram',
      bucket_range[OFFSET(0)],
      udf_aggregate_json_sum(value)
    )
  ) AS histogram_aggregates
FROM
  aggregated
LEFT JOIN `moz-fx-data-shared-prod.telemetry_derived.latest_versions` AS latest_versions
  ON latest_versions.channel = aggregated.channel
  WHERE app_version >= (latest_version - 2)
GROUP BY
  1,
  2,
  3,
  4,
  5,
  6,
  7
),
aggregated_histograms AS (
  SELECT
    client_id,
    os,
    app_version,
    app_build_id,
    channel,
    bucket_range.first_bucket AS first_bucket,
    bucket_range.last_bucket AS last_bucket,
    bucket_range.num_buckets AS num_buckets,
    metric,
    metric_type,
    key,
    process,
    agg_type,
    udf.map_sum(ARRAY_CONCAT_AGG(value)) AS aggregates
  FROM
    intermediate_histogram, UNNEST(histogram_aggregates)
  GROUP BY
    client_id,
    os,
    app_version,
    app_build_id,
    channel,
    first_bucket,
    last_bucket,
    num_buckets,
    metric,
    metric_type,
    key,
    process,
    agg_type
),
pre_bucket_counts AS (SELECT
  udf_js.sample_id(client_id) AS sample_id,
  client_id,
  os,
  app_version,
  app_build_id,
  aggregated_histograms.channel,
  CONCAT(client_id, os, app_version, app_build_id, aggregated_histograms.channel) AS join_key,
  ARRAY_AGG(
    STRUCT<
      first_bucket INT64,
      last_bucket INT64,
      num_buckets INT64,
      metric STRING,
      metric_type STRING,
      key STRING,
      process STRING,
      agg_type STRING,
      aggregates ARRAY<STRUCT<key STRING, value INT64>>
    >(
      first_bucket,
      last_bucket,
      num_buckets,
      metric,
      metric_type,
      key,
      process,
      agg_type,
      aggregates
    )
  ) AS histogram_aggregates
FROM
  aggregated_histograms
LEFT JOIN `moz-fx-data-shared-prod.telemetry_derived.latest_versions` AS latest_versions
  ON latest_versions.channel = aggregated_histograms.channel
  WHERE app_version >= (latest_version - 2)
GROUP BY
  client_id,
  os,
  app_version,
  app_build_id,
  channel
),
bucket_counts AS (
  SELECT
    sample_id,
    client_id,
    os,
    app_version,
    app_build_id,
    channel,
    first_bucket,
    last_bucket,
    num_buckets,
    metric,
    metric_type,
    key,
    process,
    agg_type,
    aggregates,
    os = 'Windows'
    AND channel = 'release' AS sampled
  FROM
    pre_bucket_counts
  CROSS JOIN
    UNNEST(histogram_aggregates)
  WHERE
    first_bucket IS NOT NULL
),
static_combos AS (
  SELECT
    NULL AS os,
    NULL AS app_build_id
  UNION ALL
  SELECT
    NULL AS os,
    '*' AS app_build_id
  UNION ALL
  SELECT
    '*' AS os,
    NULL AS app_build_id
  UNION ALL
  SELECT
    '*' AS os,
    '*' AS app_build_id
),
all_combos AS (
  SELECT
    * EXCEPT (os, app_build_id),
    COALESCE(combo.os, table.os) AS os,
    COALESCE(combo.app_build_id, table.app_build_id) AS app_build_id
  FROM
    bucket_counts table
  CROSS JOIN
    static_combos combo
),
normalized_histograms AS (
  SELECT
    * EXCEPT (sampled) REPLACE(
    -- This returns true if at least 1 row has sampled=true.
    -- ~0.0025% of the population uses more than 1 os for the same set of dimensions
    -- and in this case we treat them as Windows+Release users when fudging numbers
      mozfun.glam.histogram_normalized_sum(
        mozfun.map.sum(ARRAY_CONCAT_AGG(aggregates)),
        IF(MAX(sampled), 10.0, 1.0)
      ) AS aggregates
    )
  FROM
    all_combos
  GROUP BY
    sample_id,
    client_id,
    os,
    app_version,
    app_build_id,
    channel,
    first_bucket,
    last_bucket,
    num_buckets,
    metric,
    metric_type,
    key,
    process,
    agg_type
),
pre_probe_counts AS (SELECT
  os,
  app_version,
  app_build_id,
  channel,
  first_bucket,
  last_bucket,
  num_buckets,
  metric,
  metric_type,
  normalized_histograms.key AS key,
  process,
  agg_type,
  STRUCT<key STRING, value FLOAT64>(
    CAST(aggregates.key AS STRING),
    1.0 * SUM(aggregates.value)
  ) AS record
FROM
  normalized_histograms
CROSS JOIN
  UNNEST(aggregates) AS aggregates
GROUP BY
  os,
  app_version,
  app_build_id,
  channel,
  first_bucket,
  last_bucket,
  num_buckets,
  metric,
  metric_type,
  key,
  process,
  agg_type,
  aggregates.key
),
probe_counts AS
(SELECT
  IF(os = '*', NULL, os) AS os,
  app_version,
  IF(app_build_id = '*', NULL, app_build_id) AS app_build_id,
  channel,
  metric,
  metric_type,
  key,
  process,
  first_bucket,
  max(last_bucket) as last_bucket,
  max(num_buckets) as num_buckets,
  agg_type AS client_agg_type,
  'histogram' AS agg_type,
  CAST(ROUND(SUM(record.value)) AS INT64) AS total_users,
  mozfun.glam.histogram_fill_buckets_dirichlet(
    mozfun.map.sum(ARRAY_AGG(record)),
    mozfun.glam.histogram_buckets_cast_string_array(udf_get_buckets(first_bucket, max(last_bucket), max(num_buckets), metric_type)),
    CAST(ROUND(SUM(record.value)) AS INT64)
  ) AS histogram
FROM pre_probe_counts
GROUP BY
  os,
  app_version,
  app_build_id,
  channel,
  metric,
  metric_type,
  key,
  process,
  client_agg_type,
  first_bucket
),
    finalextract AS
    (
         SELECT * replace(mozfun.glam.histogram_cast_json(histogram) AS histogram),
                ARRAY<STRUCT<key string,value float64>>[
                ('0.1', mozfun.glam.percentile(0.1, histogram, metric_type)),
                ('1', mozfun.glam.percentile(1, histogram, metric_type)),
                ('5', mozfun.glam.percentile(5, histogram, metric_type)),
                ('25', mozfun.glam.percentile(25, histogram, metric_type)),
                ('50', mozfun.glam.percentile(50, histogram, metric_type)),
                ('75', mozfun.glam.percentile(75, histogram, metric_type)),
                ('95', mozfun.glam.percentile(95, histogram, metric_type)),
                ('99', mozfun.glam.percentile(99, histogram, metric_type)),
                ('99.9', mozfun.glam.percentile(99.9, histogram, metric_type)) ] AS percentiles
         FROM   probe_counts
    )
  SELECT * replace(mozfun.glam.histogram_cast_json(percentiles) AS percentiles)
  FROM   finalextract
