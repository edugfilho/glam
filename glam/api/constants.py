PRODUCT_FIREFOX_LEGACY = 1
PRODUCT_FENIX = 2
PRODUCT_FOG = 3

PRODUCT_CHOICES = (
    (PRODUCT_FIREFOX_LEGACY, "legacy"),
    (PRODUCT_FENIX, "fenix"),
    (PRODUCT_FOG, "fog"),
)
PRODUCT_NAMES = dict(PRODUCT_CHOICES)
PRODUCT_IDS = {v: k for k, v in PRODUCT_NAMES.items()}

CHANNEL_NIGHTLY = 1
CHANNEL_BETA = 2
CHANNEL_RELEASE = 3

CHANNEL_CHOICES = (
    (CHANNEL_NIGHTLY, "nightly"),
    (CHANNEL_BETA, "beta"),
    (CHANNEL_RELEASE, "release"),
)
CHANNEL_NAMES = dict(CHANNEL_CHOICES)
CHANNEL_IDS = {v: k for k, v in CHANNEL_NAMES.items()}

AGGREGATION_HISTOGRAM = 1
AGGREGATION_PERCENTILE = 2
AGGREGATION_CHOICES = (
    (AGGREGATION_HISTOGRAM, "histogram"),
    (AGGREGATION_PERCENTILE, "percentiles"),
)
AGGREGATION_NAMES = dict(AGGREGATION_CHOICES)
AGGREGATION_IDS = {v: k for k, v in AGGREGATION_NAMES.items()}

PROCESS_ANY = 0
PROCESS_PARENT = 1
PROCESS_CONTENT = 2
PROCESS_GPU = 3

PROCESS_CHOICES = (
    (PROCESS_ANY, "*"),
    (PROCESS_PARENT, "parent"),
    (PROCESS_CONTENT, "content"),
    (PROCESS_GPU, "gpu"),
)
PROCESS_NAMES = dict(PROCESS_CHOICES)
PROCESS_IDS = {v: k for k, v in PROCESS_NAMES.items()}

GCS_BUCKET = 'moz-fx-data-glam-prod-fca7-etl-data'
