# Assumptions
- Current go code doesn't need any change.
- Setup only for a dev environment, that is, more work needs to be done for QA and PROD environments (mainly the terraform code). For example, there is no env setting.

# Notes
- Setup as simple as possible to while still getting the objective done.
- For simplicity reasons I've not setup anything to host the terraform state file. In real world scenario I'd use cloud terraform or an S3 bucket (with DynamoDB locking) to store it.
- when running TF plan you will need to provide:
    - GitHub repository in the form OWNER/REPO: in my case "andycpu/shippit"
    - GCP project ID: in my case: "shippit-473611"
- Terraform will fail to create the cloud run service. In fact, the service should be created. But it will fail to start as there is no image yet. This is something to be improved of course.

# Prerequisites (GCP and Github)
- create an account in GCP
- create a project in GCP
- download gcloud cli
- Ensure you’re logged in with rights to enable APIs and create IAM. Run:
    - gcloud auth application-default login
    - gcloud config set project [YOUR_GCP_PROJECT_ID]

- run terraform locally to spin up the cloud run service and all its dependencies (SA, permissions, etc) in GCP. Run:
    - cd infra
    - terraform init
    - terraform plan

- fork the repo [shippit](https://github.com/andycpu/shippit)
- in your new repo, add a new repository variable "GCP_PROJECT_ID" for the repo. It's value has to be your GCP project ID.
- 





# Build
docker build -t shippit/webapp:1.0.0 .

# Run locally
docker run --rm -p 8080:8080 -e LOG_LEVEL=info shippit/webapp:1.0.0

# Test locally
curl -f localhost:8080/healthz


# Pending
docker push to ECR / artifactory
deploy pipeline