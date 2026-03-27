variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "terraform-challenge-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}
