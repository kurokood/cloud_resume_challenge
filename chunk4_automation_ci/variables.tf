variable "region" {
  default = "us-east-1"
}

data "aws_caller_identity" "current" {}
