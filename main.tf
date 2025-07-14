
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-terraform-demo-bucket-123456"
  acl    = "private"
}
  
