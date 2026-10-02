data "aws_iam_policy_document" "assume_role_policy" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_exec_policy" {
  version = "2012-10-17"
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"
  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_provider" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_iam_policy" "task_execution_policy" {
  name        = "${local.prefix}-task-exec-role-policy"
  path        = "/"
  description = "Allow retrieving images and adding to logs"
  policy      = data.aws_iam_policy_document.task_exec_policy.json
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${local.prefix}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_policy.arn
}

resource "aws_iam_role" "app_iam_role" {
  name               = "${local.prefix}-resume-task"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "${local.prefix}-resume"

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "resume" {
  family = "${local.prefix}-resume"
  container_definitions = templatefile("templates/ecs/container-definitions.json.tpl", {
    app_image        = var.ecr_image_resume
    log_group_name   = aws_cloudwatch_log_group.ecs_task_logs.name
    log_group_region = data.aws_region.current.region
    allowed_hosts    = aws_lb.resume.dns_name
  })
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.app_iam_role.arn

  tags = local.common_tags
}

resource "aws_security_group" "ecs_service" {
  description = "Access for the ECS service"
  name        = "${local.prefix}-ecs-service"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [
      aws_security_group.lb.id,
    ]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_ecs_service" "resume" {
  name             = "${local.prefix}-resume"
  cluster          = aws_ecs_cluster.main.name
  task_definition  = aws_ecs_task_definition.resume.family
  desired_count    = 1
  depends_on       = [aws_lb_listener.resume_https]
  platform_version = "1.4.0"

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
    ]
    security_groups = [
      aws_security_group.ecs_service.id,
    ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.resume.arn
    container_name   = "resume"
    container_port   = 80
  }
}
