output "role_arns" {
  description = "ARNs of IAM roles created"
  value = {
    ec2_instance_role = aws_iam_role.ec2_instance_role.arn
  }
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2.name
}
