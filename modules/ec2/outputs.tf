output "instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.app[*].id
}

output "private_ips" {
  description = "Private IPs of EC2 instances"
  value       = aws_instance.app[*].private_ip
}
