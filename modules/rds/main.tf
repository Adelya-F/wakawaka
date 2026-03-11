resource "aws_db_subnet_group" "main" {
  name       = "lks-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "lks-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier             = "lks-rds-orders"
  engine                 = "postgres"
  engine_version         = "15.10"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp3"

  db_name  = "ordersdb"
  username = "dbadmin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.sg_rds_id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  deletion_protection = false
  skip_final_snapshot = true

  tags = { Name = "lks-rds-orders" }
}
