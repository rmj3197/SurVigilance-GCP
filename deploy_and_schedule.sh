#!/bin/bash

PROJECT_ID="survigilance-data-tool" # PROJECT ID NEEDS TO BE CHANGED TO YOUR PROJECT ID
IMAGE_PATH="us-central1-docker.pkg.dev/survigilance-data-tool/survigilance-repo/survigilance-test:latest" #IMAGE_PATH THIS ALSO NEEDS TO BE UPDATED
JOB_NAME="survigilance-test-run"
VPC_NAME="survigilance-vpc" # Name for the VPC network

CPU="8"
MEMORY="16Gi"
TIMEOUT="2h"

# List of regions where the Job will run
REGIONS=(
    "us-central1"
    "southamerica-east1"
    "asia-east2"
    "africa-south1"
    "europe-west8"
)

SCHEDULES=(
    "0,15,30,45 1 * * *"   
    "0 2 * * *"            
    "0,15,30,45 8 * * *"  
    "0 9 * * *"           
    "0,15,30,45 17 * * *"  
    "0 18 * * *"           
)

SERVICE_ACCOUNT="956218653298-compute@developer.gserviceaccount.com" #PLEASE UPDATE WITH YOUR SERVICE ACCOUNT

gcloud config set project "${PROJECT_ID}"

if ! gcloud compute networks describe "${VPC_NAME}" > /dev/null 2>&1; then
    echo "Creating VPC network: ${VPC_NAME}"
    gcloud compute networks create "${VPC_NAME}" --subnet-mode=custom
else
    echo "VPC network ${VPC_NAME} already exists."
fi

SUBNET_COUNTER=1

for REGION in "${REGIONS[@]}"; do

    SUBNET_NAME="${VPC_NAME}-subnet-${REGION}"
    ROUTER_NAME="${VPC_NAME}-router-${REGION}"
    NAT_NAME="${VPC_NAME}-nat-${REGION}"
    IP_NAME="${VPC_NAME}-ip-${REGION}"

    CIDR_RANGE="10.128.${SUBNET_COUNTER}.0/24"

    # Create Subnet
    if ! gcloud compute networks subnets describe "${SUBNET_NAME}" --region="${REGION}" > /dev/null 2>&1; then
        echo "   Creating Subnet ${SUBNET_NAME} (${CIDR_RANGE})"
        gcloud compute networks subnets create "${SUBNET_NAME}" \
            --network="${VPC_NAME}" \
            --region="${REGION}" \
            --range="${CIDR_RANGE}" \
            --quiet
    else
        echo "   Subnet ${SUBNET_NAME} already exists."
    fi

    if ! gcloud compute routers describe "${ROUTER_NAME}" --region="${REGION}" > /dev/null 2>&1; then
        echo "   Creating Cloud Router ${ROUTER_NAME}"
        gcloud compute routers create "${ROUTER_NAME}" \
            --network="${VPC_NAME}" \
            --region="${REGION}" \
            --quiet
    fi

    if ! gcloud compute addresses describe "${IP_NAME}" --region="${REGION}" > /dev/null 2>&1; then
        echo "   Reserving Static IP ${IP_NAME}"
        gcloud compute addresses create "${IP_NAME}" --region="${REGION}" --quiet
    fi

    if ! gcloud compute routers nats describe "${NAT_NAME}" --router="${ROUTER_NAME}" --region="${REGION}" > /dev/null 2>&1; then
        echo "   Creating Cloud NAT ${NAT_NAME}"
        gcloud compute routers nats create "${NAT_NAME}" \
            --router="${ROUTER_NAME}" \
            --region="${REGION}" \
            --nat-custom-subnet-ip-ranges="${SUBNET_NAME}" \
            --nat-external-ip-pool="${IP_NAME}" \
            --quiet
    else
        echo "   Cloud NAT ${NAT_NAME} already exists."
    fi

    gcloud run jobs deploy "${JOB_NAME}" \
        --image "${IMAGE_PATH}" \
        --region "${REGION}" \
        --cpu "${CPU}" \
        --memory "${MEMORY}" \
        --task-timeout "${TIMEOUT}" \
        --max-retries="1" \
        --network "${VPC_NAME}" \
        --subnet "${SUBNET_NAME}" \
        --vpc-egress "all-traffic" \
        --quiet

    if [ $? -eq 0 ]; then
        echo "[OK] Job deployed successfully to ${REGION} with VPC access."
        
        SCHEDULER_LOCATION="us-central1"
        TIME_ZONE="Etc/UTC"

        i=1
        for SCHEDULE_PATTERN in "${SCHEDULES[@]}"; do
            SCHEDULER_NAME="${JOB_NAME}-${REGION}-trigger-${i}"
            API_URI="https://${REGION}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${PROJECT_ID}/jobs/${JOB_NAME}:run"

            if gcloud scheduler jobs describe "${SCHEDULER_NAME}" --location "${SCHEDULER_LOCATION}" > /dev/null 2>&1; then
                gcloud scheduler jobs update http "${SCHEDULER_NAME}" \
                    --location "${SCHEDULER_LOCATION}" \
                    --schedule "${SCHEDULE_PATTERN}" \
                    --time-zone "${TIME_ZONE}" \
                    --uri="${API_URI}" \
                    --http-method="POST" \
                    --oauth-service-account-email="${SERVICE_ACCOUNT}" \
                    --quiet
                ACTION="Updated"
            else
                gcloud scheduler jobs create http "${SCHEDULER_NAME}" \
                    --location "${SCHEDULER_LOCATION}" \
                    --schedule "${SCHEDULE_PATTERN}" \
                    --time-zone "${TIME_ZONE}" \
                    --uri="${API_URI}" \
                    --http-method="POST" \
                    --oauth-service-account-email="${SERVICE_ACCOUNT}" \
                    --quiet
                ACTION="Created"
            fi

            if [ $? -eq 0 ]; then
                echo "   [OK] Scheduler ${ACTION}: ${SCHEDULER_NAME}"
            fi
            
            ((i++))
        done

    else
        echo "[FAILED] Failed to deploy Cloud Run job to ${REGION}."
    fi

    ((SUBNET_COUNTER++))
    echo ""
done

echo "All deployments finished."
