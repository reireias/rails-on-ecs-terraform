resource "aws_lb" "app" {
  name = "${local.name}-app"
  # NOTE: allow from internet
  # tfsec:ignore:AWS005
  internal        = false
  subnets         = [for _, v in aws_subnet.public : v.id]
  security_groups = [aws_security_group.alb.id]

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.logs.bucket
    enabled = true
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  # NOTE: Return 404 to all not CloudFront requests.
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "app_from_cloudfront" {
  listener_arn = aws_lb_listener.app.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["blue"].arn
  }

  condition {
    http_header {
      http_header_name = "x-pre-shared-key"
      values           = ["TODO"]
    }
  }

  # NOTE: Ignore target group switch
  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_target_group" "app" {
  for_each = toset(["blue", "green"])

  name        = "${local.name}-app-${each.key}"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path    = "/health_checks"
    matcher = "200-299"
  }
}
