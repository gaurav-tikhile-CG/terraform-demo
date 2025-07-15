provider "aws" {
  region = var.aws_region
}

data "aws_iam_users" "all" {}

output "iam_user_names" {
  value = data.aws_iam_users.all.names
}
