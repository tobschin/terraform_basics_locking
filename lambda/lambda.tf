terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18.0"
    }
  }

  required_version = ">= 1.2"
}


provider "aws" {
  region = "eu-west-1"
}


terraform {
  backend "s3" {
    bucket = "lockbuckets_name" # bucket locking here
    key    = "env/test/terraform.tfstate"
    region = "eu-west-1"
  }
}


# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_hello_world" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

    tags = {
    Name        = "My bucket"
    Environment = "TF_Test"
  }
}

# Package the Lambda function code
data "archive_file" "lambda_hello_world" {
  type        = "zip"
  source_file = "${path.module}/hello-world/app.mjs"
  output_path = "${path.module}/hello-world/app.zip"
}

# Lambda function
resource "aws_lambda_function" "lambda_hello_world" {
  filename         = data.archive_file.lambda_hello_world.output_path
  function_name    = "hello-world"
  role             = aws_iam_role.lambda_hello_world.arn
  handler          = "app.lambdaHandler"
  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256
  runtime = "nodejs20.x"

  environment {
    variables = {
      ENVIRONMENT = "TF_Test"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Name        = "My bucket"
    Environment = "TF_Test"
  }
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "lambdabucketmisas"

  tags = {
    Name        = "My bucket"
    Environment = "TF_Test"
  }
}


resource "aws_s3_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "app.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)


  tags = {
    Name        = "My bucket"
    Environment = "TF_Test"
  }

}


output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.lambda_hello_world.function_name
}


resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "hello_world" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.lambda_hello_world.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "hello_world" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /hello-world"
  target    = "integrations/${aws_apigatewayv2_integration.hello_world.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_hello_world.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}


output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}

output "hello_world_url" {
  description = "Base URL for API Gateway stage."

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/hello-world"
}
