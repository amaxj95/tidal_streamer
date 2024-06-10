variable "project_id" {
  description = "The ID of the GCP project to use"
  type        = string
}

variable "region" {
  description = "The GCP region to create resources in"
  type        = string
  default     = "us-east4"
}

variable "zone" {
  description = "The GCP zone to create resources in"
  type        = string
  default     = "us-east4-a"
}

variable "domain_name" {
  description = "The domain name for the managed SSL certificate"
  type        = string
}