output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = module.main_network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.main_network.public_subnet_ids
}

output "load_balancer_dns_name" {
  description = "Public DNS name of the application load balancer"
  value       = module.main_compute.load_balancer_dns_name
}

output "app_data_bucket_name" {
  description = "Name of the generated per-environment S3 data bucket"
  value       = aws_s3_bucket.app_data.bucket
}

output "instance_ids" {
  description = "IDs of the provisioned compute instances"
  value       = module.main_compute.instance_ids
}
