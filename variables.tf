variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Short project identifier used in resource naming"
  default     = "acme"
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

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the compute module"
}

variable "instance_count" {
  type        = number
  description = "Number of compute instances to launch"
  default     = 1
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks permitted to reach instances on the admin port"
  default     = []
}
