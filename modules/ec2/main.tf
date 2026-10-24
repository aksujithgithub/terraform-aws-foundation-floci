# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.ec2_sg_id]
  iam_instance_profile   = var.iam_instance_profile

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    db_secret_name      = var.db_secret_name
    aws_region          = var.aws_region
    localstack_endpoint = var.localstack_endpoint
  }))

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-app-${count.index + 1}"
  })
}

resource "aws_lb_target_group_attachment" "app" {
  count            = var.instance_count
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.app[count.index].id
  port             = 5000
}
