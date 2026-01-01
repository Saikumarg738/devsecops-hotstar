terraform {
  backend "s3" {
    bucket = "devsecops-hotstar-sai"
    key    = "EKS/terraform.tfstate"
    region = "us-east-1"
  }
}
