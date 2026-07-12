output "load_balancer_dns_name" {
  value = aws_lb.app.dns_name
}

output "instance_ids" {
  value = aws_instance.app[*].id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}
