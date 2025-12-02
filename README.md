# SurVigilance-GCP

This repository contains the necessary scripts and configurations for deploying and managing the SurVigilance application on Google Cloud Platform (GCP).

## Project Aim

The SurVigilance-GCP project aims to provide a comprehensive, automated framework for continuously testing the "SurVigilance" package across various Google Cloud Platform regions. It focuses on ensuring regular operation and robust testing through scheduled job execution and automated reporting.

## Shell Scripts Overview

*   `build_and_push.sh`: This script builds a Docker image of the application and pushes it to Google Artifact Registry. It ensures that the required Google Cloud services are enabled and creates an Artifact Registry repository if one doesn't exist.
*   `deploy_and_schedule.sh`: This script deploys the Docker image as a Cloud Run job and sets up Cloud Scheduler jobs to trigger it periodically across multiple Google Cloud regions. It requires the user to update placeholder variables for `PROJECT_ID`, `IMAGE_PATH`, and `SERVICE_ACCOUNT`.
*   `run_tests.sh`: This script executes Pytest tests, generates an Excel report of the test results, and uploads the report to a specified Google Cloud Storage (GCS) bucket. Users must update the placeholder for `<YOUR BUCKET NAME>` in the script.

## Schematic Diagram Depicting the Workflow

![GCP Workflow](GCP_Workflow.png "GCP_Workflow")