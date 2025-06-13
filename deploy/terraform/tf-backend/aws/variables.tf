variable "aws_region" {
  description = "AWS region for the backend resources"
  type        = string
  default     = "us-west-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  type        = string
  default     = "nextjs-fastapi-terraform-state"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}