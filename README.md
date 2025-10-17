# ctfd-gcp

An IaaC deployment of [CTFd](https://ctfd.io/) in Google Cloud Platform, intended to be reliable and easily scalable for larger CTFs. Inspired by [DownUnderCTF/ctfd-appengine](https://github.com/DownUnderCTF/ctfd-appengine).

Used for pwned3 CTF. More details on the pwned3 infrastructure [here](https://www.atteniemi.com/ctf-infra-writeup/).

### Architecture Overview

CTFd is deployed on App Engine Flex, which provides load balancing, auto-scaling, health checks and more right out of the box.

The application resides on a VPC which has a direct peering connection to a Memorystore Redis, allowing us connect CTFd to a cache that, again, requires very little manual maintenance.

There is also a private services access connection to Cloud SQL which is used as the database for CTFd. Again, scaling and other operation are easy.

CTFd stores uploaded challenge files in a Google Storage Bucket.

Furthermore, both the Memorystore and Cloud SQL are assigned only private IP addresses within our VPC, making inaccessible from the internet and enhancing security.

![](docs/architecture_overview.svg)

NOTE: this diagram is missing i.e. buckets used for challenge storage and buckets storing the CTFd Dockerfile

## Cloud Run (Terraform)

A modern, serverless deployment option using Cloud Run v2 with managed infrastructure.

### Architecture

- **Cloud Run v2**: Serverless container platform with autoscaling (0-100 instances)
- **Cloud SQL for PostgreSQL 15+**: Regional HA database with private IP via Private Service Connect
- **Memorystore Redis**: STANDARD_HA tier for caching inside the VPC
- **Global HTTPS Load Balancer**: Managed SSL certificates and global edge network
- **GCS Bucket**: S3-compatible storage for challenge file uploads via HMAC keys
- **Secret Manager**: Secure storage for sensitive data (SECRET_KEY, database password, HMAC keys)
- **VPC with Serverless VPC Access**: Private networking for Cloud Run to access Redis and Cloud SQL

### Quick Start

1. **Build and push the CTFd image** to Artifact Registry:
   ```bash
   # See detailed instructions in docs/build-image.md
   export PROJECT_ID="your-gcp-project-id"
   export REGION="us-central1"
   
   # Create Artifact Registry repository
   gcloud artifacts repositories create ctfd \
     --repository-format=docker \
     --location=${REGION} \
     --project=${PROJECT_ID}
   
   # Build and push image
   cd app_engine
   gcloud builds submit \
     --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/ctfd/ctfd:latest \
     --project=${PROJECT_ID}
   cd ..
   ```

2. **Configure Terraform variables**:
   ```bash
   cd terraform-cloudrun
   cp vars.auto.tfvars.example vars.auto.tfvars
   # Edit vars.auto.tfvars with your project_id and image URL
   ```

3. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure DNS**:
   - Point your domain A record to the load balancer IP (shown in Terraform outputs)
   - Wait for the managed SSL certificate to provision (can take 10-15 minutes)

5. **Access CTFd**:
   - Navigate to `https://ctf.qnqsec.team` (or your configured domain)
   - Complete the CTFd setup wizard

### Configuration

All configuration is managed through `vars.auto.tfvars`. Key variables:

- `project_id`: Your GCP project ID
- `region`: Deployment region (default: `us-central1`)
- `domain`: Your CTFd domain (default: `ctf.qnqsec.team`)
- `ctfd.image`: Container image from Artifact Registry
- `ctfd.min_instances`: Minimum Cloud Run instances (default: 0)
- `ctfd.max_instances`: Maximum Cloud Run instances (default: 100)
- `ctfd.cpu`: CPU allocation per instance (default: "1")
- `ctfd.memory`: Memory allocation per instance (default: "1Gi")
- `db.tier`: Cloud SQL machine type (default: `db-custom-2-7680`)
- `db.version`: PostgreSQL version (default: `POSTGRES_15`)
- `redis.tier`: Redis tier (default: `STANDARD_HA`)

See `vars.auto.tfvars.example` for all available options and detailed comments.

### Outputs

After deployment, Terraform provides:

- `lb_ip_address`: Global IP for DNS configuration
- `cloudrun_url`: Direct Cloud Run service URL
- `uploads_bucket`: GCS bucket name for uploads
- `redis_host` / `redis_port`: Redis connection details
- `sql_connection_name`: Cloud SQL connection name

### Scaling

Cloud Run automatically scales based on traffic:
- Scales to zero when idle (saves costs)
- Scales up to `max_instances` under load
- Each instance handles up to `concurrency` concurrent requests (default: 70)

Adjust scaling parameters in `vars.auto.tfvars`:
```hcl
ctfd = {
  min_instances = 1      # Keep warm instances
  max_instances = 200    # Handle higher traffic
  concurrency   = 100    # More requests per instance
}
```

### Security

- All secrets stored in Secret Manager (never in tfstate)
- Cloud SQL and Redis only accessible via private IP within VPC
- Serverless VPC Access connector enables secure Cloud Run networking
- Managed SSL certificates for HTTPS
- IAM-based access control for all resources

### Migration from App Engine

The Cloud Run deployment is completely separate from the existing App Engine deployment in the `terraform/` directory. Both can coexist in different projects or can be migrated gradually.

For more details on building the CTFd image, see [docs/build-image.md](docs/build-image.md).
