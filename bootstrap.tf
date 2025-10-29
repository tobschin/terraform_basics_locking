terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}


provider "aws" {
  region = "eu-west-1"
}


resource "aws_s3_bucket" "tf_locking_bucket" {
  bucket = "lockbuckets_name"

  tags = {
    Name        = "My bucket"
    Environment = "TF_Test"
  }
}
