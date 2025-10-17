# CTFd on Cloud Run - Terraform Configuration

This directory contains Terraform configuration for deploying CTFd on Google Cloud Run v2 with fully managed infrastructure.

## Prerequisites

- Google Cloud Platform account with billing enabled
- `gcloud` CLI installed and authenticated
- Terraform >= 1.0 installed
- CTFd Docker image built and pushed to Artifact Registry (see [../docs/build-image.md](../docs/build-image.md))

## Quick Start

1. **Build and push the CTFd image**:
   ```bash
   # See ../docs/build-image.md for detailed instructions
   cd ../app_engine
   gcloud builds submit --tag us-central1-docker.pkg.dev/YOUR_PROJECT_ID/ctfd/ctfd:latest
   cd ../terraform-cloudrun
   ```

2. **Configure variables**:
   ```bash
   cp vars.auto.tfvars.example vars.auto.tfvars
   # Edit vars.auto.tfvars with your project_id and configuration
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the plan**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **Configure DNS**:
   - After deployment, note the `lb_ip_address` from Terraform outputs
   - Create an A record pointing your domain to this IP address
   - Wait 10-15 minutes for the managed SSL certificate to provision

7. **Access CTFd**:
   - Navigate to your domain (e.g., https://ctf.qnqsec.team)
   - Complete the CTFd setup wizard

## Architecture

This deployment creates:

- **Cloud Run v2 Service**: Serverless container platform running CTFd
- **VPC Network**: Private network with subnets for resources
- **Serverless VPC Access Connector**: Allows Cloud Run to access VPC resources
- **Cloud SQL for PostgreSQL**: Regional HA database with private IP
- **Memorystore Redis**: HA cache instance within the VPC
- **GCS Bucket**: S3-compatible storage for CTFd uploads
- **Secret Manager**: Secure storage for sensitive configuration
- **Global HTTPS Load Balancer**: SSL termination and global routing
- **Managed SSL Certificate**: Automatic SSL/TLS for your domain

## Configuration

### Required Variables

Edit `vars.auto.tfvars` and set:

- `project_id`: Your GCP project ID
- `ctfd.image`: Your CTFd image URL from Artifact Registry

### Optional Variables

All other variables have sensible defaults for `us-central1` and `ctf.qnqsec.team`. Customize as needed:

```hcl
region = "us-central1"
domain = "ctf.qnqsec.team"

ctfd = {
  image         = "us-central1-docker.pkg.dev/YOUR_PROJECT/ctfd/ctfd:latest"
  min_instances = 0
  max_instances = 100
  cpu           = "1"
  memory        = "1Gi"
  concurrency   = 70
  theme         = "qnqsec"
}

db = {
  tier    = "db-custom-2-7680"  # 2 vCPU, 7.5 GB RAM
  version = "POSTGRES_15"
  disk_gb = 10
}

redis = {
  tier    = "STANDARD_HA"
  size_gb = 1
}
```

## File Structure

- `main.tf`: Provider configuration
- `vars.tf`: Variable definitions
- `vars.auto.tfvars.example`: Example configuration file
- `apis.tf`: Enable required GCP APIs
- `vpc.tf`: VPC, subnets, and networking
- `secrets.tf`: Secret Manager resources
- `db.tf`: Cloud SQL PostgreSQL instance
- `redis.tf`: Memorystore Redis instance
- `bucket.tf`: GCS bucket and HMAC keys
- `cloudrun.tf`: Cloud Run v2 service configuration
- `loadbalancer.tf`: Global HTTPS load balancer
- `outputs.tf`: Output values

## Outputs

After successful deployment:

- `lb_ip_address`: IP address for DNS A record
- `cloudrun_url`: Direct Cloud Run URL (bypasses load balancer)
- `uploads_bucket`: GCS bucket name for uploads
- `redis_host`, `redis_port`: Redis connection details
- `sql_connection_name`: Cloud SQL instance connection
- `domain_configuration`: DNS setup instructions

## Scaling

Cloud Run automatically scales based on traffic. Adjust in `vars.auto.tfvars`:

```hcl
ctfd = {
  min_instances = 1    # Keep 1 instance always running (faster cold starts)
  max_instances = 200  # Scale up to 200 instances
  concurrency   = 100  # 100 concurrent requests per instance
}
```

Cost optimization:
- `min_instances = 0`: Pay only for active usage, but slower cold starts
- `min_instances = 1`: Faster response, small constant cost

## Security Notes

- All secrets are stored in Secret Manager (not in tfstate)
- Cloud SQL and Redis use private IP addresses only
- VPC isolation for backend services
- IAM-based access control
- Managed SSL certificates for HTTPS

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete:
- The Cloud SQL database (and all data)
- The GCS bucket (and all uploads)
- All other infrastructure

Ensure you have backups before running destroy!

## Troubleshooting

### SSL Certificate Not Provisioning

Managed SSL certificates can take 10-15 minutes to provision. Check status:

```bash
gcloud compute ssl-certificates describe ctfd-cert --global
```

Ensure your domain's A record points to the load balancer IP.

### Cloud Run Service Not Starting

Check Cloud Run logs:

```bash
gcloud run services logs read ctfd --region=us-central1
```

Common issues:
- Image not found: Ensure the image is built and pushed to Artifact Registry
- Secret access denied: Verify IAM permissions
- Database connection failed: Check Cloud SQL instance is running

### Cannot Access via Domain

1. Verify DNS A record points to `lb_ip_address` output
2. Check SSL certificate status (see above)
3. Try accessing via `cloudrun_url` output to test Cloud Run directly
4. Check load balancer configuration in Cloud Console

## Support

For detailed build instructions, see [../docs/build-image.md](../docs/build-image.md)

For issues, please file a GitHub issue in the repository.
