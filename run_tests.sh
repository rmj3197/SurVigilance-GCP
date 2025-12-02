#!/bin/bash

REGION=${GCP_REGION:-"local"}

TIME_ZONE="Etc/UTC"

TIMESTAMP=$(TZ="${TIME_ZONE}" date +%Y%m%d-%H-%M)
FILENAME="report-${TIMESTAMP}-${REGION}.xlsx"

pytest -n 4 --flake-finder --flake-runs=3 --random-order --excelreport=${FILENAME} -k "test_scrape_ and _sb.py" --tb long|| true

echo "Copying report to gs://survigilance-results/${FILENAME}"
gsutil cp ${FILENAME} gs://survigilance-results/${FILENAME}

echo "Done."
