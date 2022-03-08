terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.69"
    }
  }
}

provider "aws" {
  region = local.region

  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

data "aws_vpc" "selected" {
    default = true
}

# Declare local variables

locals {
  bucket_name = "s3-bucket-${var.bucket-suffix}"
  region      = "${var.bucket-suffix}"
  vpc_id      = data.aws_vpc.selected.id
}

# create IAM users, roles & policy
resource "aws_iam_user" "admin_user" {
  name = "admin_user"
}

resource "aws_iam_user" "monitor_user" {
  name = "monitor_user"
}

resource "aws_iam_group" "admin" {
  name = "admin"
  path = "/users/"
}

resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/users/"
}

resource "aws_iam_group" "readonly" {
  name = "readonly"
  path = "/users/"
}

resource "aws_iam_role" "s3_role" {
  name = "s3_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.s3_role.arn, aws_iam_user.admin_user]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]
  }
}

resource "aws_iam_policy" "s3policy" {
  name        = "policy"
  description = "s3 IAM policy"
  policy      = data.aws_iam_policy_document.bucket_policy.json
}

# Create S3 Bucket
resource "aws_s3_bucket" "demos3bucket" {
    bucket = "${local.bucket_name}" 
    acl = "${var.bucket-acl}"   
}
