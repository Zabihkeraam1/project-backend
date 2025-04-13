terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# _____________________Creating App-runner___________________
resource "aws_apprunner_service" "backend_service" {
  service_name = "${var.project}-backend-${random_id.bucket_suffix.hex}"

  source_configuration {
    authentication_configuration {
      connection_arn = "arn:aws:apprunner:us-east-1:135808921133:connection/new-connection/45c0ab0285b64f8abd68e04dde58f1ff"
    }

    auto_deployments_enabled = true

    code_repository {
      repository_url = var.repository_url

      source_code_version {
        type  = "BRANCH"
        value = var.branch
      }

      code_configuration {
        configuration_source = "API"
         code_configuration_values {
          runtime        = "PYTHON_311"
          build_command = "python3 -m venv /app/venv && source /app/venv/bin/activate && pip3 install --upgrade pip && pip3 install fastapi uvicorn && pip3 install -r ./backend/requirements.txt && pip3 list"
          # start_command = "pip3 install --upgrade pip && source /app/venv/bin/activate && pip3 install fastapi uvicorn && pip3 install -r ./backend/requirements.txt && uvicorn backend.main:app --host 0.0.0.0 --port 8080" 
          start_command = "./start.sh"
          port           = 8080
          runtime_environment_variables = {
            NODE_ENV        = "production"
            FRONTEND_DOMAIN  = "aws_cloudfront_distribution.cdn.domain_name"
            S3_BUCKET_NAME  = "aws_s3_bucket.frontend_bucket.bucket"
            DB_USER           = "aws_db_instance.my_database.username"
            DB_PASSWORD       = "var.db_password"
            DB_HOST           = "aws_db_instance.my_database.address"
            DB_NAME           = "aws_db_instance.my_database.db_name"
            DB_PORT           = "5432"
            DB_SSL            = "true" # Always use SSL with public RDS
          }
        }
      }
    }
  }

  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }

  tags = {
    Name        = "${var.project}--backend"
    Project     = var.project
    Environment = "production"
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}

output "apprunner_service_url" {
  value       = aws_apprunner_service.backend_service.service_url
}
