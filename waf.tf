resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.useast1

  name        = "${local.name}-cloudfront"
  description = "WAF for CloudFront."
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "crs"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "crs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "sqli"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "sqli"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront"
    sampled_requests_enabled   = true
  }
}
