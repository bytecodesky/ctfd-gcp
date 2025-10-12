# VPC network for CTFd
resource "google_compute_network" "ctfd_vpc" {
  name                    = "ctfd-vpc"
  auto_create_subnetworks = false
}

# Subnet for VPC
resource "google_compute_subnetwork" "ctfd_subnet" {
  name          = "ctfd-subnet"
  ip_cidr_range = var.main_subnet_cidr
  region        = var.region
  network       = google_compute_network.ctfd_vpc.id

  # Enable Private Google Access for GCS, etc.
  private_ip_google_access = true
}

# Serverless VPC Access connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  provider = google-beta
  name     = "ctfd-vpc-connector"
  region   = var.region

  subnet {
    name = google_compute_subnetwork.connector_subnet.name
  }

  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 3
}

# Dedicated subnet for VPC Access connector
resource "google_compute_subnetwork" "connector_subnet" {
  name          = "ctfd-connector-subnet"
  ip_cidr_range = var.access_connector_cidr
  region        = var.region
  network       = google_compute_network.ctfd_vpc.id
}

# Allocate IP range for Private Service Connect (for Cloud SQL)
resource "google_compute_global_address" "private_ip_address" {
  name          = "ctfd-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.ctfd_vpc.id
}

# Private Service Connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.ctfd_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
