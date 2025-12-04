#!/bin/bash

ZONE_PATH=$(curl -s --connect-timeout 1 -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/zone" || true)
REGION=$(basename "$ZONE_PATH")

echo "Detected execution region: ${REGION}"

TIME_ZONE="Etc/UTC"

TIMESTAMP=$(TZ="${TIME_ZONE}" date +%Y%m%d-%H-%M)
FILENAME="report-${TIMESTAMP}-${REGION}.xlsx"

pytest -n 4 --flake-finder --flake-runs=3 --random-order --excelreport=${FILENAME} -k "test_scrape_ and _sb.py" --tb long|| true

# Update with <YOUR BUCKET NAME>
echo "Copying report to gs://survigilance-results/${FILENAME}"
gsutil cp ${FILENAME} gs://survigilance-results/${FILENAME} # gsutil has been replaced by gcloud gcloud cli which can also be here here. 

echo "Done."
