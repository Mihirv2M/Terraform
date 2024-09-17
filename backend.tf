terraform {
  backend "s3" {
    bucket = "terraform-mihir-local-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

// enable versioning on the S3 bucket so that every update to a file in the bucket actually creates a new version of that file  
# resource "aws_s3_bucket_versioning" "enabled" {
#     bucket = "terraform-mihir-local-state"
#     versioning_configuration {
#       status = "Enabled"
#     }
# }

//to turn server-side encryption on by default for all data written to this S3 bucket. This ensures that your state files, and any secrets they might contain, are always encrypted on disk when stored in S3:
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = "terraform-mihir-local-state"
    rule{
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
  }
} 
