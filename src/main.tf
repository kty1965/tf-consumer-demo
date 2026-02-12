terraform {
  required_version = ">= 1.0"

  backend "local" {
    # For demo purposes, using local backend
    # In production, use S3 backend configured via backend.conf
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_pet" "demo" {
  length = 2
}

output "pet_name" {
  value       = random_pet.demo.id
  description = "Random pet name for demo"
}
