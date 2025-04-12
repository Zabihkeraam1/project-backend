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
        #   runtime        = "NODEJS_18"
          runtime        = "PYTHON_311"
        #   build_command = "npm --prefix ./backend install --production"
          build_command = "python3 -m pip install --upgrade pip && python3 -m pip install uvicorn fastapi && [ -f ./backend/requirements.txt ] && python3 -m pip install -r ./backend/requirements.txt"
        #   start_command = "node ./backend/server.js" 
          start_command = "python3 -m uvicorn backend.main:app --host 0.0.0.0 --port 8080" 
          port           = 8080
          runtime_environment_variables = {
            PYTHONUNBUFFERED = "1"
            NODE_ENV        = "production"
          }
        }
      }
    }
  }

  instance_configuration {
    cpu               = "1024"
    memory            = "2048"
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
