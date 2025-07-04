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
    key            = "recipe-sharing-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-up-and-running-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for the website
resource "aws_s3_bucket" "site" {
  bucket = "monvillarin.com"
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json
}

data "aws_iam_policy_document" "site" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ACM Certificate
resource "aws_acm_certificate" "cert" {
  domain_name               = "monvillarin.com"
  validation_method         = "DNS"
  subject_alternative_names = ["*.monvillarin.com"]

  lifecycle {
    create_before_destroy = true
  }
}

# Route 53

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.primary.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# CloudFront
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

resource "aws_cloudfront_function" "www_to_nonwww" {
  name    = "www-to-nonwww"
  runtime = "cloudfront-js-1.0"
  comment = "Redirects www to non-www"
  publish = true
  code    = <<CODE
function handler(event) {
    var request = event.request;
    var host = request.headers.host.value;
    if (host.startsWith("www.")) {
        var new_host = host.substring(4);
        var response = {
            statusCode: 301,
            statusDescription: "Moved Permanently",
            headers: {
                "location": { "value": "https://" + new_host + request.uri }
            }
        };
        return response;
    }
    return request;
}
CODE
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac-monvillarin.com"
  description                       = "S3 OAC for monvillarin.com"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = "monvillarin.com.s3.us-east-1.amazonaws.com"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2"
  price_class         = "PriceClass_100"

  aliases = ["monvillarin.com", "www.monvillarin.com"]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "monvillarin.com.s3.us-east-1.amazonaws.com"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.www_to_nonwww.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}



# Route 53 Records
resource "aws_route53_record" "root_a" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "monvillarin.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.monvillarin.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "blog_cname" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "blog.monvillarin.com"
  type    = "CNAME"
  ttl     = 300
  records = ["hashnode.network"]
}

resource "aws_route53_record" "ns" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "monvillarin.com"
  type    = "NS"
  ttl     = 172800
  records = [
    "ns-836.awsdns-40.net.",
    "ns-1689.awsdns-19.co.uk.",
    "ns-1436.awsdns-51.org.",
    "ns-480.awsdns-60.com."
  ]
}

resource "aws_route53_record" "soa" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "monvillarin.com"
  type    = "SOA"
  ttl     = 900
  records = ["ns-480.awsdns-60.com. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
}
