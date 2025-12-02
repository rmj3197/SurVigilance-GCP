#!/bin/bash

PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
REPO_NAME="survigilance-repo"
IMAGE_NAME="survigilance-test"

gcloud services enable artifactregistry.googleapis.com cloudbuild.googleapis.com

if ! gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" > /dev/null 2>&1; then
    echo "Creating repo: $REPO_NAME"
    gcloud artifacts repositories create "$REPO_NAME" \
        --repository-format=docker \
        --location="$REGION" \
        --description="SurVigilance tests"
fi

if [ ! -f "Dockerfile" ]; then
    echo "Error: Dockerfile missing in current dir."
    exit 1
fi

IMAGE_URI="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest"
echo "Building target: $IMAGE_URI"

gcloud builds submit --tag "$IMAGE_URI" .
