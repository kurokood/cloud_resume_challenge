terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# DYNAMODB, LAMBDA, IAM ROLE, API GATEWAY #

resource "aws_dynamodb_table" "site_analytics" {
  name         = "SiteAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ip"

  attribute {
    name = "ip"
    type = "S"
  }
}

# Create lambda function
resource "aws_lambda_function" "site_analytics" {
  function_name    = "SiteAnalytics-lambda-function"
  role             = aws_iam_role.site_analytics.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  filename         = "SiteAnalytics_function.zip"
  source_code_hash = filebase64sha256("SiteAnalytics_function.zip")
  timeout          = 3
  memory_size      = 128
  package_type     = "Zip"

  ephemeral_storage {
    size = 512
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/SiteCounter"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

# Create IAM role
resource "aws_iam_role" "site_analytics" {
  name = "SiteAnalytics-role"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create IAM policy
resource "aws_iam_policy" "site_analytics" {
  name        = "SiteAnalytics-policy"
  description = "Allows Lambda to log to CloudWatch and access DynamoDB"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup"
        ],
        "Resource" : "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.site_analytics.function_name}:*"
        ]
      },
      {
        "Sid" : "UpdateDynamoDB",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Scan"
        ],
        "Resource" : [
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.site_analytics.name}"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "site_analytics" {
  name       = "SiteAnalytics-attach-policy"
  roles      = [aws_iam_role.site_analytics.name]
  policy_arn = aws_iam_policy.site_analytics.arn
}

# Create the API Gateway
resource "aws_apigatewayv2_api" "site_analytics_api" {
  name          = "SiteAnalytics-api"
  protocol_type = "HTTP"
  description   = "HTTP API for VisitorCounter Lambda"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

# Create a Lambda Integration
resource "aws_apigatewayv2_integration" "site_analytics_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.site_analytics_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.site_analytics.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Create a route for the integration
resource "aws_apigatewayv2_route" "site_analytics_default_route" {
  api_id    = aws_apigatewayv2_api.site_analytics_api.id
  route_key = "GET /"

  target = "integrations/${aws_apigatewayv2_integration.site_analytics_lambda_integration.id}"
}

# Create a default stage with throttling
resource "aws_apigatewayv2_stage" "site_analytics_default_stage" {
  api_id      = aws_apigatewayv2_api.site_analytics_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}

# Lambda permission to allow API Gateway to invoke it
resource "aws_lambda_permission" "site_analytics_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.site_analytics.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.site_analytics_api.execution_arn}/*/*"
}
