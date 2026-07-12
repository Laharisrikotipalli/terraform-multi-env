variable "environment" {
  type        = string
  description = "The active deployment environment (dev, staging, production)"
}

variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names for uniqueness"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to span"
  default     = 2
}
