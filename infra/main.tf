terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
  cloud {
    organization = "lrosenfeldt-personal"

    workspaces {
      name = "opencampus-devops"
    }
  }

  required_version = ">= 1.2.0"
}

variable "region" {
  type        = string
  description = "AWS region to deploy to."
  default     = "eu-central-1"
}

provider "aws" {
  region = var.region
}
