provider "aws" {
  region = "us-east-1"
}

data "aws_iam_users" "all" {}

output "iam_user_names" {
  value = data.aws_iam_users.all.names
}
