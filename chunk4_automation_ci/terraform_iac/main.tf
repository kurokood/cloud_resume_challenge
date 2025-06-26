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

# CHUNK 1: S3, CLOUDFRONT, CERTIFICATE MANAGER, ROUTE53 #

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "monvillarin_com" {
  bucket = "monvillarin.com"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "monvillarin_com" {
  bucket = aws_s3_bucket.monvillarin_com.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_website_configuration" "monvillarin_com" {
  bucket = aws_s3_bucket.monvillarin_com.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "monvillarin_com" {
  bucket = aws_s3_bucket.monvillarin_com.id

  versioning_configuration {
    status     = "Suspended"
    mfa_delete = "Disabled"
  }
}

resource "aws_s3_bucket_policy" "monvillarin_com" {
  bucket = aws_s3_bucket.monvillarin_com.id
  policy = jsonencode({
    Id = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Action = "s3:GetObject"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::026045577315:distribution/EQF3Y3Z48KAQW"
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Resource = "arn:aws:s3:::monvillarin.com/*"
        Sid      = "AllowCloudFrontServicePrincipal"
      },
    ]
    Version = "2008-10-17"
  })
}

resource "aws_s3_bucket" "www_monvillarin_com" {
  bucket = "www.monvillarin.com"
}

resource "aws_s3_bucket_versioning" "www_monvillarin_com" {
  bucket = aws_s3_bucket.www_monvillarin_com.id

  versioning_configuration {
    status     = "Suspended"
    mfa_delete = "Disabled"
  }

}

resource "aws_s3_bucket_website_configuration" "www_monvillarin_com" {
  bucket = aws_s3_bucket.www_monvillarin_com.id

  redirect_all_requests_to {
    host_name = "monvillarin.com"
    protocol  = "https"
  }
}

resource "aws_cloudfront_distribution" "monvillarin-com" {
  aliases = ["monvillarin.com", ]

  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  staging             = false
  wait_for_deployment = true
  web_acl_id          = null

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress                   = true
    default_ttl                = 0
    field_level_encryption_id  = null
    max_ttl                    = 0
    min_ttl                    = 0
    origin_request_policy_id   = null
    realtime_log_config_arn    = null
    response_headers_policy_id = null
    smooth_streaming           = false
    target_origin_id           = "monvillarin.com.s3.us-east-1.amazonaws.com"
    trusted_key_groups         = []
    trusted_signers            = []
    viewer_protocol_policy     = "redirect-to-https"

    grpc_config {
      enabled = false
    }
  }

  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = "monvillarin.com.s3.us-east-1.amazonaws.com"
    origin_access_control_id = "E2N2H931RAB9WX"
    origin_id                = "monvillarin.com.s3.us-east-1.amazonaws.com"
    origin_path              = null
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:026045577315:certificate/6f9106a0-d143-4bdb-8d9c-60ec70b4e3ee"
    cloudfront_default_certificate = false
    iam_certificate_id             = null
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "www-monvillarin-com" {
  aliases = [
  "www.monvillarin.com", ]

  continuous_deployment_policy_id = null
  default_root_object             = null
  enabled                         = true
  http_version                    = "http2"
  is_ipv6_enabled                 = true
  price_class                     = "PriceClass_100"
  retain_on_delete                = false
  staging                         = false

  wait_for_deployment = true
  web_acl_id          = null

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress                   = true
    default_ttl                = 0
    field_level_encryption_id  = null
    max_ttl                    = 0
    min_ttl                    = 0
    origin_request_policy_id   = null
    realtime_log_config_arn    = null
    response_headers_policy_id = null
    smooth_streaming           = false
    target_origin_id           = "www.monvillarin.com.s3.us-east-1.amazonaws.com"
    trusted_key_groups         = []
    trusted_signers            = []
    viewer_protocol_policy     = "redirect-to-https"

    grpc_config {
      enabled = false
    }
  }

  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = "www.monvillarin.com.s3-website-us-east-1.amazonaws.com"
    origin_access_control_id = null
    origin_id                = "www.monvillarin.com.s3.us-east-1.amazonaws.com"
    origin_path              = null

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "SSLv3",
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2",
      ]
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:026045577315:certificate/6f9106a0-d143-4bdb-8d9c-60ec70b4e3ee"
    cloudfront_default_certificate = false
    iam_certificate_id             = null
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_route53_zone" "monvillarin-com" {
  name = "monvillarin.com"
}

resource "aws_route53_record" "a_monvillarin_com" {
  zone_id = "Z07109463UH31DUYYHTAA"
  name    = "monvillarin.com"
  type    = "A"

  alias {
    name                   = "d1txs7h0r7q3g9.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "a_www_monvillarin_com" {
  zone_id = "Z07109463UH31DUYYHTAA"
  name    = "www.monvillarin.com"
  type    = "A"

  alias {
    name                   = "d2k6iwa1zm1x8f.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ns_monvillarin_com" {
  zone_id = "Z07109463UH31DUYYHTAA"
  name    = "monvillarin.com"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-480.awsdns-60.com.",
    "ns-1436.awsdns-51.org.",
    "ns-1689.awsdns-19.co.uk.",
    "ns-836.awsdns-40.net."
  ]
}

resource "aws_route53_record" "soa_monvillarin_com" {
  zone_id = "Z07109463UH31DUYYHTAA"
  name    = "monvillarin.com"
  type    = "SOA"
  ttl     = 900
  records = [
    "ns-480.awsdns-60.com. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
  ]
}

resource "aws_route53_record" "cname_monvillarin_com" {
  zone_id = "Z07109463UH31DUYYHTAA"
  name    = "_3eb7646d38fc7aabed05b01098cd9e12.monvillarin.com"
  type    = "CNAME"
  ttl     = 300
  records = [
    "_15c2bb186c05b077c7d62fba8a351a76.zfyfvmchrl.acm-validations.aws."
  ]
}

resource "aws_route53_record" "blog_monvillarin_com" {
  zone_id = "Z07109463UH31DUYYHTAA"
  name    = "blog.monvillarin.com"
  type    = "CNAME"
  ttl     = 300
  records = [
    "hashnode.network"
  ]
}

resource "aws_acm_certificate" "monvillarin_com" {
  domain_name       = "monvillarin.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.monvillarin.com",
    "monvillarin.com"
  ]

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  tags = {}
}

# API #


