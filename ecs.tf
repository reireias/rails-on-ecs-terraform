resource "aws_ecs_cluster" "main" {
  name = "${local.name}-main"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name}-app"
  execution_role_arn       = aws_iam_role.ecs.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]

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

resource "aws_ecs_service" "app" {
  name            = "${local.name}-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  health_check_grace_period_seconds = 30

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets         = [for _, v in aws_subnet.ecs : v.id]
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app["blue"].arn
    container_name   = "web"
    container_port   = 3000
  }

  # NOTE: Use FARGATE_SPOT
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 0
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 0
    weight            = 100
  }

  # NOTE: Ignore some attributes which will change by CodeDeploy.
  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer,
    ]
  }
}
