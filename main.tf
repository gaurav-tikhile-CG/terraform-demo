provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "example" {
  bucket = "my-example-bucket-${var.region}"
  acl    = "private"
}
