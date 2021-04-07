resource "aws_cloudfront_distribution" "main" {
  provider = aws.useast1

  origin {
    origin_id   = "alb"
    domain_name = "alb.${local.domain}"

    custom_header {
      name  = "x-pre-shared-key"
      value = data.aws_kms_secrets.secrets.plaintext["cloudfront_shared_key"]
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = [local.domain]

  web_acl_id = aws_wafv2_web_acl.cloudfront.arn

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    smooth_streaming       = true
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern = "/assets/*"

    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    smooth_streaming       = true
    compress               = true
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false

    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
    minimum_protocol_version = "TLSv1.2_2019"
    ssl_support_method       = "sni-only"
  }

  logging_config {
    bucket = aws_s3_bucket.logs.bucket_domain_name
    prefix = "cloudfront/"
  }

  depends_on = [aws_route53_record.acm_cloudfront]
}

resource "aws_cloudfront_origin_access_identity" "main" {}
