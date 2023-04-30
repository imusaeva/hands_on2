terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "irina-tentech-backend-s3"
    key    = "tf-handson2-state-file"
  }
}