variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "adelya" {
  description = "Your name for resource naming (lowercase, no spaces, e.g. john)"
  type        = string
  default     = "yourname"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  default     = "TechnoCloud2026!"
  sensitive   = true
}

variable "notification_email" {
  description = "Email for SNS notifications"
  type        = string
  default     = "adelyafzy@gmail.com"
}
