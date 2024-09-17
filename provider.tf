terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
   }
  }
}


provider "aws" {
  region = "us-east-1"
  # access_key = var.AWS_ACCESS_KEY_ID
  # secret_key = var.AWS_SECRET_ACCESS_KEY
  }
  # export AWS_ACCESS_KEY_ID="anaccesskey"
  # export AWS_SECRET_ACCESS_KEY="asecretkey"
  # export AWS_REGION="us-west-2"

  
   
   