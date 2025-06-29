# Terraform configuration to create:
# - GKE Autopilot Cluster
# - Artifact Registry (Docker)

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "ecommerce_repo" {
  provider = google
  location = var.region
  repository_id = "ecommerce-repo"
  format = "DOCKER"
  description = "Docker repo for ecommerce project"
}

resource "google_container_cluster" "autopilot_cluster" {
  name     = "ecommerce-cluster"
  location = var.region
  enable_autopilot = true
}

# Required IAM bindings for Cloud Build to deploy to GKE
resource "google_project_iam_member" "cloudbuild_gke_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_service" "enabled_services" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  service = each.key
}

variable "project_id" {
  description = "Your GCP Project ID"
  type        = string
}

variable "project_number" {
  description = "Your GCP Project Number"
  type        = string
}

variable "region" {
  description = "Region to deploy resources"
  default     = "us-central1"
} 

output "gke_cluster_name" {
  value = google_container_cluster.autopilot_cluster.name
}

output "artifact_registry_url" {
  value = google_artifact_registry_repository.ecommerce_repo.id
}


