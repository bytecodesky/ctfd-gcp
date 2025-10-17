# Building and Pushing the CTFd Image with qnqsec-theme

This guide explains how to build and push a custom CTFd Docker image with the qnqsec-theme to Google Artifact Registry.

## Prerequisites

- Google Cloud SDK (`gcloud`) installed and authenticated
- Docker installed (for local builds)
- Access to the GCP project specified in your Terraform configuration

## Step 1: Create Artifact Registry Repository

First, create a Docker repository in Artifact Registry in the `us-central1` region:

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"

# Create Artifact Registry repository
gcloud artifacts repositories create ctfd \
  --repository-format=docker \
  --location=${REGION} \
  --description="CTFd container images" \
  --project=${PROJECT_ID}
```

## Step 2: Build and Push the Image

You have two options for building and pushing the image: using Cloud Build (recommended) or Docker locally.

### Option A: Using Cloud Build (Recommended)

Cloud Build is faster and doesn't require Docker to be installed locally.

```bash
# Navigate to the app_engine directory (contains Dockerfile and patch.txt)
cd app_engine

# Build and push using Cloud Build
gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/ctfd/ctfd:latest \
  --project=${PROJECT_ID}
```

You can also tag with a specific version:

```bash
# Build with version tag
gcloud builds submit \
  --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/ctfd/ctfd:3.4.3 \
  --project=${PROJECT_ID}
```

### Option B: Using Docker Locally

If you prefer to build locally:

```bash
# Configure Docker to authenticate with Artifact Registry
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Navigate to the app_engine directory
cd app_engine

# Build the image locally
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/ctfd/ctfd:latest .

# Push to Artifact Registry
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/ctfd/ctfd:latest
```

## Step 3: Reference the Image in Terraform

After building and pushing the image, update your Terraform configuration to reference it.

In your `vars.auto.tfvars` file (or `terraform.tfvars`), set the image URL:

```hcl
ctfd = {
  image         = "us-central1-docker.pkg.dev/your-gcp-project-id/ctfd/ctfd:latest"
  min_instances = 0
  max_instances = 100
  cpu           = "1"
  memory        = "1Gi"
  concurrency   = 70
  theme         = "qnqsec"
}
```

Replace `your-gcp-project-id` with your actual GCP project ID.

## Customizing the Image

The current Dockerfile is based on CTFd 3.4.3 and applies patches from `patch.txt`. To customize:

1. **Change CTFd version**: Modify the `FROM` line in `app_engine/Dockerfile`
   ```dockerfile
   FROM ctfd/ctfd:3.5.0  # Update to desired version
   ```

2. **Add qnqsec-theme**: If you have a custom theme, add it to the image:
   ```dockerfile
   FROM ctfd/ctfd:3.4.3
   
   WORKDIR /opt/CTFd
   COPY ./patch.txt /opt/CTFd/patch.txt
   RUN patch -s -p1 < patch.txt
   
   # Add custom theme
   COPY ./qnqsec-theme /opt/CTFd/CTFd/themes/qnqsec
   ```

3. **Rebuild and push** using one of the methods above

## Verifying the Image

After pushing, you can verify the image exists:

```bash
gcloud artifacts docker images list \
  ${REGION}-docker.pkg.dev/${PROJECT_ID}/ctfd \
  --project=${PROJECT_ID}
```

## Using the Image with Terraform

Once the image is pushed, you can deploy it with Terraform:

```bash
cd terraform-cloudrun
terraform init
terraform plan
terraform apply
```

The Cloud Run service will pull the image from Artifact Registry during deployment.

## Important Notes

- The image must be built and pushed **before** running `terraform apply`
- If you update the image, redeploy Cloud Run by updating the image tag or running `terraform apply` again
- For production, use versioned tags (e.g., `3.4.3`) instead of `latest` for better version control
- The `CTFD_THEME` environment variable in the Terraform configuration should match the theme directory name in your image
