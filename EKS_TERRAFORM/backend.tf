terraform {
  backend "s3" {
    bucket = "devsecops-hotstar-sai"
    key    = "EKS/terraform.tfstate"
    resion = "us-east-1"
  }
}
