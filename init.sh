#!/bin/sh

# Get service name from config.yaml file
SERVICE_MAME=$(grep 'name:' config.yaml | awk '{ print $2}')
CONFIG_NAME=$SERVICE_MAME-config.yaml
GC_CONFIG_PATH=gs://dm-build-notifiers/$CONFIG_NAME
GC_PROJECT=$1
GC_PROJECT_NUMBER=$2
GC_PUB_SUB_INVOKER_ACC_NAME="cloud-run-pubsub-invoker"
GC_PUB_SUB_INVOKER_ACC_DISPLAY_NAME="Cloud Run Pub/Sub Invoker"
GC_PUB_SUB_TOPIC_NAME="cloud-builds"

if [ -n "$GC_PROJECT" ];
  then
    echo "Setting up build notification flow for project "$GC_PROJECT
  else
    echo "Provide google cloud project id"
    exit 0
fi

if [ -n "$GC_PROJECT_NUMBER" ];
  then
    continue
  else
    echo "Provide google cloud project number"
    exit 0
fi

# 1) Upload config to bucket
gsutil cp config.yaml $GC_CONFIG_PATH

# 2) Deploy notifier to Cloud Run
gcloud run deploy $SERVICE_MAME \
  --image=us-east1-docker.pkg.dev/gcb-release/cloud-build-notifiers/http:latest \
  --project=$GC_PROJECT \
  --update-env-vars=CONFIG_PATH=$GC_CONFIG_PATH,PROJECT_ID=$GC_PROJECT \
  --platform=managed \
  --region=us-east1 \
  --allow-unauthenticated \
  --service-account=$GC_PROJECT-compute@$GC_PROJECT.iam.gserviceaccount.com

# 3) Grant Pub/Sub permissions to create authentication tokens in your project
gcloud projects add-iam-policy-binding $GC_PROJECT \
   --member=serviceAccount:service-$GC_PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
   --role=roles/iam.serviceAccountTokenCreator

# 4) Create a service account to represent your Pub/Sub subscription identity
# Check if $GC_PUB_SUB_INVOKER_ACC_NAME acc is exists
GC_PUB_SUB_INVOKER_ACC=$(gcloud iam service-accounts describe $GC_PUB_SUB_INVOKER_ACC_NAME@$GC_PROJECT.iam.gserviceaccount.com 2>/dev/null)

if [ -n "$GC_PUB_SUB_INVOKER_ACC" ];
  then
    echo "$GC_PUB_SUB_INVOKER_ACC_NAME is exists. Skip creating..."
    continue
  else
    gcloud iam service-accounts create $GC_PUB_SUB_INVOKER_ACC_NAME \
      --display-name $GC_PUB_SUB_INVOKER_ACC_DISPLAY_NAME

    gcloud run services add-iam-policy-binding service-name \
      --member=serviceAccount:$GC_PUB_SUB_INVOKER_ACC_NAME@$GC_PROJECT.iam.gserviceaccount.com \
      --role=roles/run.invoker
fi

# 5) Create the cloud-builds topic to receive build update messages for your notifier
# Check if $GC_PUB_SUB_INVOKER_ACC_NAME acc is exists
GC_PUB_SUB_TOPIC=$(gcloud pubsub topics list | grep $GC_PUB_SUB_TOPIC_NAME)

if [ -n "$GC_PUB_SUB_INVOKER_ACC" ];
  then
    echo "$GC_PUB_SUB_TOPIC_NAME topics are exist. Skip creating..."
    continue
  else
    gcloud pubsub topics create $GC_PUB_SUB_INVOKER_ACC
fi

# 6) Create a Pub/Sub push subscriber for your notifier
# Get url of deployed cloud run service
CLOUD_RUN_SERVICE_URL=$(gcloud run services list --platform managed | grep build-notifier-virgin-dev | awk '{print $4}')
gcloud pubsub subscriptions create $SERVICE_MAME-subscripton \
   --topic=$GC_PUB_SUB_TOPIC_NAME \
   --push-endpoint=$CLOUD_RUN_SERVICE_URL \
   --push-auth-service-account=cloud-run-pubsub-invoker@$GC_PROJECT.iam.gserviceaccount.com