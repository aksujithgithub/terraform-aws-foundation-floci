resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-db-subnet-group" })
}

resource "aws_db_instance" "this" {
  identifier        = "${var.project}-${var.environment}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]

  # LocalStack — skip real backups/snapshots
  backup_retention_period = 0
  skip_final_snapshot     = true
  publicly_accessible     = false

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-mysql" })
}

# ---------------------------------------------------------------------------
# Store DB credentials in Secrets Manager
# ---------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "db" {
  name        = "${var.project}/${var.environment}/db"
  description = "RDS MySQL credentials for ${var.project} ${var.environment}"

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-db-secret" })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    db_host     = aws_db_instance.this.address
    db_port     = tostring(aws_db_instance.this.port)
    db_name     = aws_db_instance.this.db_name
    db_username = aws_db_instance.this.username
    db_password = var.db_password
  })
}
