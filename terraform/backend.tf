terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "eks/node-app/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-south-1"
}

# -----------------------------
# S3 Bucket for Terraform State
# -----------------------------
resource "aws_s3_bucket" "tf_state" {
  bucket = "my-terraform-state-bucket"

  tags = {
    Name        = "terraform-state-bucket"
    Environment = "shared"
  }
}

# -----------------------------
# Enable Versioning (CRITICAL)
# -----------------------------
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------
# Enable Server-Side Encryption
# -----------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------
# Block Public Access (SECURITY)
# -----------------------------
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------
# DynamoDB Table for Locking
# -----------------------------
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-lock-table"
    Environment = "shared"
  }
}