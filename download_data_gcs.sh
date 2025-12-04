#!/bin/bash

GCS_BUCKET_NAME="survigilance-results"

echo "Downloading .xlsx files from gs://${GCS_BUCKET_NAME}"
gcloud storage cp "gs://${GCS_BUCKET_NAME}/*.xlsx" "/Users/raktimmukhopadhyay/Documents/SurVigilance-GCP/Data Files"

if [ $? -eq 0 ]; then
  echo "Successfully downloaded .xlsx files."
else
  echo "Error downloading .xlsx files."
  exit 1
fi