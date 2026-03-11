# ─── ORDERS BUCKET ───────────────────────────
resource "aws_s3_bucket" "orders" {
  bucket        = "lks-orders-${var.your_name}-2026"
  force_destroy = true
  tags          = { Name = "lks-orders-${var.your_name}-2026" }
}

resource "aws_s3_bucket_versioning" "orders" {
  bucket = aws_s3_bucket.orders.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "orders" {
  bucket = aws_s3_bucket.orders.id
  rule {
    id     = "orders-lifecycle"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration { days = 365 }
  }
}

resource "aws_s3_bucket_cors_configuration" "orders" {
  bucket = aws_s3_bucket.orders.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "orders" {
  bucket                  = aws_s3_bucket.orders.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "orders" {
  bucket     = aws_s3_bucket.orders.id
  depends_on = [aws_s3_bucket_public_access_block.orders]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAll"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.orders.arn, "${aws_s3_bucket.orders.arn}/*"]
    }]
  })
}

# ─── LOGS BUCKET ─────────────────────────────
resource "aws_s3_bucket" "logs" {
  bucket        = "lks-logs-${var.your_name}-2026"
  force_destroy = true
  tags          = { Name = "lks-logs-${var.your_name}-2026" }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "logs-lifecycle"
    status = "Enabled"
    transition {
      days          = 7
      storage_class = "INTELLIGENT_TIERING"
    }
    expiration { days = 90 }
  }
}
