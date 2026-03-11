variable "private_subnet_ids" { type = list(string) }
variable "sg_rds_id"          { type = string }
variable "db_password"        { type = string; sensitive = true }
