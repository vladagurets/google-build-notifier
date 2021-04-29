## Requrements:
- ```gcloud``` - https://cloud.google.com/sdk/docs/install
- ```gsutil``` - https://cloud.google.com/storage/docs/gsutil_install

## Manual:

\**this manual means that you have cofigured Google Project and Cloud Build flow*

1. Specify name of cloud service, branch name, repo name and delivery url in ```config.yaml```
2. Log in to google cloud via cli
3. Run ```sh init.sh {Google_Project_Id} {Google_Project_Number}```

It will deploy applicaton via Cloud Run and create Subscription to build events for specific project.
Then build activity will be sent to provided delivery url in config.yaml.

## Links:
Advanced manual: [https://cloud.google.com/build/docs/configuring-notifications/configure-http](https://cloud.google.com/build/docs/configuring-notifications/configure-http)

Cloud Run: [https://console.cloud.google.com/run?project={Project_Id}](https://console.cloud.google.com/run?project={Project_Id})

Pub/Sub subscriptons: [https://console.cloud.google.com/cloudpubsub/subscription/list?project={Project_Id}](https://console.cloud.google.com/cloudpubsub/subscription/list?project={Project_Id})
