variable "environment" {
  type        = string
  description = "The active deployment environment (dev, staging, production)"
}

variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names for uniqueness"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where instances and the load balancer are deployed"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the load balancer"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the compute instances"
}

variable "instance_type" {
  type        = string
  description = "The size of the compute instance"
}

variable "instance_count" {
  type        = number
  description = "Number of instances to launch"
  default     = 1
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks permitted administrative access; empty disables it"
  default     = []
}
