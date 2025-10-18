# CTFd Cloud Run Deployment

This directory contains Terraform configuration for deploying CTFd on Google Cloud Run v2 with a modern, serverless architecture.

## Architecture

- **Cloud Run v2**: Serverless container platform with autoscaling
- **Cloud SQL PostgreSQL 15+**: Regional HA database with private IP
- **Memorystore Redis**: STANDARD_HA tier for high-availability caching  
- **Cloud Storage**: GCS bucket with HMAC keys for S3-compatible uploads
- **Secret Manager**: Secure storage for secrets (SECRET_KEY, DB password, S3 keys)
- **Global HTTPS Load Balancer**: Managed SSL certificate with serverless NEG
- **VPC Networking**: Private networking with Serverless VPC Access connector

## Prerequisites

1. **GCP Project**: A GCP project with billing enabled
2. **Domain**: A domain name you control (for DNS and SSL certificate)
3. **Tools**: 
   - Terraform >= 1.3
   - `gcloud` CLI (authenticated)
4. **APIs**: The following APIs will be enabled automatically:
   - Compute Engine API
   - Cloud Run API
   - Cloud SQL Admin API
   - Serverless VPC Access API
   - Secret Manager API
   - Certificate Manager API

## Quick Start

### 1. Configure Variables

Copy the example variables file and edit it with your values:

```bash
cp vars.auto.tfvars.example vars.auto.tfvars
```

Edit `vars.auto.tfvars` and set at minimum:
- `project_id`: Your GCP project ID
- `domain`: Your domain name (e.g., `ctf.example.com`)

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review and Apply

```bash
terraform plan
terraform apply
```

The apply will take approximately 10-15 minutes to provision all resources.

### 4. Configure DNS

After `terraform apply` completes, note the `load_balancer_ip` from the outputs:

```bash
terraform output load_balancer_ip
```

Configure your DNS:
- **Cloudflare** (recommended): Create an A record pointing to the LB IP, enable proxy (orange cloud), set SSL to "Full (strict)"
- **Other DNS**: Create an A record pointing to the LB IP

### 5. Wait for SSL Certificate

The managed SSL certificate can take 15-60 minutes to provision. Monitor status:

```bash
terraform output ssl_cert_status
```

You can also check in the [GCP Console](https://console.cloud.google.com/net-services/loadbalancing/advanced/sslCertificates/list).

### 6. Access CTFd

Once the SSL certificate is ACTIVE, navigate to your domain:

```
https://ctf.example.com
```

Complete the CTFd setup wizard to create your admin account.

## Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP Project ID | *required* |
| `region` | GCP region | `us-central1` |
| `domain` | Domain for HTTPS | *required* |
| `ctfd.image` | CTFd Docker image | `ctfd/ctfd:3.7.0` |
| `ctfd.min_instances` | Min Cloud Run instances | `1` |
| `ctfd.max_instances` | Max Cloud Run instances | `10` |
| `ctfd.cpu` | CPU per instance | `"2"` |
| `ctfd.memory` | Memory per instance | `"2Gi"` |
| `db.tier` | Cloud SQL machine type | `db-custom-2-7680` |
| `db.availability_type` | SQL HA mode | `REGIONAL` |
| `redis.tier` | Redis tier | `STANDARD_HA` |

See `vars.auto.tfvars.example` for all available options.

### Scaling

Cloud Run will automatically scale between `min_instances` and `max_instances` based on load. Adjust these in `vars.auto.tfvars`:

```hcl
ctfd = {
  min_instances = 2    # Always keep 2 instances warm
  max_instances = 20   # Scale up to 20 under load
  # ...
}
```

Apply changes:
```bash
terraform apply
```

### Updating CTFd

To update to a new CTFd version:

1. Edit `vars.auto.tfvars`:
   ```hcl
   ctfd = {
     image = "ctfd/ctfd:3.7.1"  # New version
     # ...
   }
   ```

2. Apply:
   ```bash
   terraform apply
   ```

Cloud Run will perform a rolling update with zero downtime.

## Outputs

After deployment, Terraform provides these outputs:

```bash
terraform output                  # Show all outputs
terraform output load_balancer_ip # Show specific output
```

- `load_balancer_ip`: IP for DNS A record
- `cloud_run_url`: Direct Cloud Run URL (bypasses LB)
- `uploads_bucket_name`: GCS bucket for uploads
- `redis_host` / `redis_port`: Redis connection info
- `sql_connection_name`: Cloud SQL instance name
- `domain`: Configured domain
- `ssl_cert_status`: SSL certificate status

## Security

- **Secrets**: All secrets stored in Secret Manager, not in Terraform state
- **Private Networking**: Database and Redis accessible only via VPC
- **SQL Connection**: Cloud Run connects via unix socket (no network exposure)
- **IAM**: Least-privilege service accounts
- **HTTPS Only**: HTTP redirects to HTTPS automatically

## Troubleshooting

### SSL Certificate Not Provisioning

The managed SSL certificate requires:
1. DNS A record pointing to the load balancer IP
2. Domain ownership verification (automatic via HTTP challenge)

If stuck in PROVISIONING state:
- Verify DNS propagation: `dig ctf.example.com`
- Check certificate status in GCP Console
- Can take up to 60 minutes

### Cloud Run Service Not Starting

Check logs:
```bash
gcloud run services logs read ctfd --region us-central1 --limit 50
```

Common issues:
- Database connection: Verify Cloud SQL instance is ready
- Redis connection: Verify VPC connector is working
- Secret access: Check IAM permissions

### Connection to Database Failed

Cloud Run connects to Cloud SQL via unix socket using the annotation `run.googleapis.com/cloudsql-instances`.

Verify:
```bash
terraform output sql_connection_name
```

This should match the annotation in the Cloud Run service.

## Cost Estimation

Approximate monthly costs (us-central1, moderate usage):

- Cloud Run: $20-50 (2 vCPU, 2GB RAM, 1-10 instances)
- Cloud SQL: $100-150 (db-custom-2-7680, regional HA, 20GB)
- Redis: $80-100 (2GB, STANDARD_HA)
- Load Balancer: $20-30
- Storage: $1-5 (100GB bucket usage)
- **Total**: ~$220-335/month

Costs scale with:
- Number of Cloud Run instances (autoscaling)
- Database size and instance type
- Redis memory size
- Egress bandwidth

Use [GCP Pricing Calculator](https://cloud.google.com/products/calculator) for detailed estimates.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: Some resources may have retention:
- Secret Manager secrets (automatic deletion after 30 days)
- Cloud SQL backups (kept per backup retention policy)
- Storage buckets (set to force_destroy, will delete with contents)

## Support

For issues specific to this Terraform configuration:
- Open an issue in the repository

For CTFd issues:
- [CTFd Documentation](https://docs.ctfd.io/)
- [CTFd GitHub](https://github.com/CTFd/CTFd)

For GCP issues:
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
