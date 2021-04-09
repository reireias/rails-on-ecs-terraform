![](https://img.shields.io/static/v1?label=terraform&message=0.14.9&color=blue) ![](https://img.shields.io/static/v1?label=aws-provider&message=3.35.0&color=blue) [![fmt](https://github.com/reireias/rails-on-ecs-terraform/workflows/fmt/badge.svg)](https://github.com/reireias/rails-on-ecs-terraform/actions) [![tfsec](https://github.com/reireias/rails-on-ecs-terraform/workflows/tfsec/badge.svg)](https://github.com/reireias/rails-on-ecs-terraform/actions) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**[日本語 | Jpanese](README.ja.md)**

# rails-on-ecs-terraform
Terraform Code for Rails on AWS ECS.

It has a **SIMPLE** and **SECURE** architecture.

Rails Repository: [reireias/rails-on-ecs](https://github.com/reireias/rails-on-ecs)

## Architecture

### Orverview
![rails-on-ecs-01](https://user-images.githubusercontent.com/24800246/114057770-d7225080-98cd-11eb-8f93-507f6080ccd3.png)

It is a simple architecture using CloudFront, ALB, ECS, and Aurora.

CloudFront is configured with WAF to block attacks such as XSS and SQLi.

The domains for CloudFront and ALB are managed by Route53.

All layers have Multi-AZ level availability, so the service can continue even if a failure occurs in any AZ.

### Network
![rails-on-ecs-02](https://user-images.githubusercontent.com/24800246/114059568-7562e600-98cf-11eb-9b85-b5e288dc0b93.png)

Subnets within a VPC are subdivided by usage as shown above.

### Security Group
![rails-on-ecs-03](https://user-images.githubusercontent.com/24800246/114063905-0fc52880-98d4-11eb-9159-d9239eb9724e.png)

The Security Group is also designed to be separated for different purposes.

By specifying a different Security Group as the source of inbound rules between Security Groups, only the minimum amount of communication is allowed.

We also set up a VPC Endpoint so that we can communicate with S3 and ECR without going through the Internet.

### CD Pipeline
![rails-on-ecs-04](https://user-images.githubusercontent.com/24800246/114064398-91b55180-98d4-11eb-995e-33c424d51688.png)

The CD pipeline is run in CodePipeline, triggered by an image push to the ECR as shown above.

By triggering a push to the ECR, we can achieve a natural boundary of responsibility between Rails application developers and infrastructure engineers.

The image build is done on the GitHub Actions side.

`rails db:migrate` is executed by CodeBuild.

Deployment is done using CodeDeploy, which switches all traffic to the new version at once, so that assets references do not cause 404 errors when deployed.

## Tips

### Security
The following security measures have been implemented in accordance with the Well-Architected Framework and the best practices of the Security Hub.

- DDoS countermeasures by placing CloudFront at the front stage
- Blocking of XSS, SQLi, and other attacks through WAF managed rules
- Encryption settings for RDS
- Management of confidential information using the SSM parameter store
- Vulnerability scanning with ECR
- Security pointing by Terraform code static analysis with [tfsec](https://tfsec.dev/)

### Logging
The following logging settings are in place.

Logging should be done whenever possible. (Although this repository does not log WAFs.)

- [CloudFront](cloudfront.tf)
- [ALB](alb.tf)
- [VPC Flow Log](vpc.tf)
- [S3 Access Log](s3_codepipeline.tf)

### Certificates and DNS records
This repository uses a domain obtained from Route53, as in the implementation of [route53.tf](route53.tf).

Even if you have acquired your domain in a different way, it is a good idea to transfer it so that you can configure it from Route53.

If you can set up your domain in Route53, you can smoothly implement ACM validation and so on like [acm.tf](acm.tf).

Implementing ACM certificates and their validation DNS records:
```terraform
resource "aws_acm_certificate" "main" {
  domain_name               = local.domain
  subject_alternative_names = ["*.${local.domain}"]
  validation_method         = "DNS"
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm : record.fqdn]
}
```

### Make requests to ALB by custom headers CloudFront-only
Configure the following custom header in CloudFront.

```terraform
resource "aws_cloudfront_distribution" "main" {

  origin {
    custom_header {
      name  = "x-pre-shared-key"
      value = data.aws_kms_secrets.secrets.plaintext["cloudfront_shared_key"]
    }
    # ...
  }
  # ...
}
```

Configure the listener rules of the ALB so that only requests with the above header are sent to ECS.

```terraform
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
      values           = [data.aws_kms_secrets.secrets.plaintext["cloudfront_shared_key"]]
    }
  }

  # NOTE: Ignore target group switch
  lifecycle {
    ignore_changes = [action]
  }
}
```

By configuring it in this way, you can block the route for direct requests to the ALB without going through CloudFront.

### Avoiding rolling updates with CodeDeploy
When deploying Rails on multiple servers with rolling updates, there is a moment when references to some of the assets files such as js and css will result in a 404 error.

This happens when we get the html from the new server and go to get the js in it to the old server.

There are various ways to work around this problem, but here we simply use CodeDeploy and do not perform rolling updates to avoid it.

You can switch all requests to the new version at the same time by specifying `deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"`.

### ECS task definitions for dummies in the initial build phase
When you're in the early stages of building your product and you don't have a Rails application yet, you'll want a lightweight image that passes at least one health check and an ECS task definition that uses it.

By using the [medpeer/health_check](https://hub.docker.com/r/medpeer/health_check) image, you can create an ECS task definition that only needs to pass the health check for the specified path.

```terraform
resource "aws_ecs_task_definition" "app" {
  # ...

  # NOTE: Dummy containers for initial.
  container_definitions = <<CONTAINERS
[
  {
    "name": "web",
    "image": "medpeer/health_check:latest",
    "portMappings": [
      {
        "hostPort": 3000,
        "containerPort": 3000
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.app.name}",
        "awslogs-region": "${local.region}",
        "awslogs-stream-prefix": "web"
      }
    },
    "environment": [
      {
        "name": "NGINX_PORT",
        "value": "3000"
      },
      {
        "name": "HEALTH_CHECK_PATH",
        "value": "/health_checks"
      }
    ]
  }
]
CONTAINERS
}
```

### Use for_each to repeat Availability Zones
In case AZs are added in the future, use `for_each` for resources such as subnets that are created in the number of AZs.

For example, a public subnet can be created as follows.
```terraform
resource "aws_subnet" "public" {
  for_each = local.availability_zones

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, local.az_conf[each.key].index)

  tags = {
    Name = "${local.name}-public-${local.az_conf[each.key].short_name}"
  }
}
```

Here, we define a variable named `az_conf` as follows.

```terraform
locals {
  az_conf = {
    "ap-northeast-1a" = {
      index      = 1
      short_name = "1a"
    }
    "ap-northeast-1c" = {
      index      = 2
      short_name = "1c"
    }
    "ap-northeast-1d" = {
      index      = 3
      short_name = "1d"
    }
  }
}
```

By using the [cidrsubnet function](https://www.terraform.io/docs/language/functions/cidrsubnet.html), you can effortlessly manage CIDRs with certain rules.

If you want a list of Subnet ids, you can generate it with the following code.

```terraform
values(aws_subnet.public)[*].id
```

### Secrets with KMS
Confidential information can be encrypted with KMS and included in this repository for simple management.

By using `aws_kms_secrets`, compounding will be done by Terraform at plan time and apply time.

The usage is as follows.

- Encrypt with KMS key.
  ```console
  $ aws kms encrypt --key alias/terraform --plaintext "secret_value" --output text --query CiphertextBlob
  ```

- Create `aws_kms_secrets` data resource.
  ```terraform
  locals {
    secrets = {
      foo = "encrypted_value"
    }
  }

  # NOTE: register all secrets
  data "aws_kms_secrets" "secrets" {
    dynamic "secret" {
      for_each = local.secrets

      content {
        name    = secret.key
        payload = secret.value
      }
    }
  }
  ```

- Use decrypted value
  ```terraform
  data.aws_kms_secrets.secrets.plaintext["foo"] # set decrypted value
  ```
