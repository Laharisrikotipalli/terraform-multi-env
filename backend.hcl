bucket         = "your-org-tf-multi-env-state"
key            = "multi-env/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "tf-multi-env-lock"
encrypt        = true