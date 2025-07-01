terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-state-bucket-abc1"
    key            = "cloud-resume-challenge/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-up-and-running-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

# CHUNK 1: S3, CLOUDFRONT, CERTIFICATE MANAGER, ROUTE53 #

resource "aws_s3_bucket" "monvillarin" {
  bucket = "monvillarin"
}

resource "aws_s3_bucket_website_configuration" "monvillarin" {
  bucket = aws_s3_bucket.monvillarin.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "monvillarin" {
  bucket = aws_s3_bucket.monvillarin.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "monvillarin" {
  bucket = aws_s3_bucket.monvillarin.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "monvillarin" {
  bucket = aws_s3_bucket.monvillarin.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
    bucket_key_enabled = true
  }
}



resource "aws_cloudfront_distribution" "monvillarin" {
  origin {
    domain_name = aws_s3_bucket.monvillarin.bucket_regional_domain_name
    origin_id   = "S3-monvillarin.com"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["monvillarin.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-monvillarin.com"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.monvillarin.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_acm_certificate" "monvillarin" {
  domain_name       = "monvillarin.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "monvillarin_validation" {
  for_each = {
    for dvo in aws_acm_certificate.monvillarin.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.monvillarin.zone_id
}

resource "aws_acm_certificate_validation" "monvillarin" {
  certificate_arn         = aws_acm_certificate.monvillarin.arn
  validation_record_fqdns = [for record in aws_route53_record.monvillarin_validation : record.fqdn]
}

resource "aws_route53_zone" "monvillarin" {
  name = "monvillarin.com"
}

resource "aws_route53_record" "monvillarin_apex" {
  zone_id = aws_route53_zone.monvillarin.zone_id
  name    = "monvillarin.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.monvillarin.domain_name
    zone_id                = aws_cloudfront_distribution.monvillarin.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_function" "redirect_www" {
  name    = "redirect-www-to-non-www"
  runtime = "cloudfront-js-1.0"
  comment = "Redirects www to non-www"
  publish = true
  code = <<-EOT
function handler(event) {
    var request = event.request;
    var response = {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {
            'location': { 'value': 'https://monvillarin.com' + request.uri }
        }
    };
    return response;
}
EOT
}

resource "aws_cloudfront_distribution" "www_monvillarin" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Redirects www.monvillarin.com to monvillarin.com"
  aliases             = ["www.monvillarin.com"]

  origin {
    domain_name = "dummy-origin.example.com"
    origin_id   = "dummy-origin-for-redirect"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "dummy-origin-for-redirect"
    viewer_protocol_policy = "redirect-to-https"
    compress = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_www.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.monvillarin.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "www_monvillarin" {
  zone_id = aws_route53_zone.monvillarin.zone_id
  name    = "www.monvillarin.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www_monvillarin.domain_name
    zone_id                = aws_cloudfront_distribution.www_monvillarin.hosted_zone_id
    evaluate_target_health = false
  }
}