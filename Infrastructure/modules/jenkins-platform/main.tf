# Jenkins Platform Orchestrator
# Composes leaf modules into a complete Jenkins master-agent ECS setup

module "vpc" {
  source               = "../vpc"
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  common_tags          = var.common_tags
}

module "master_cluster" {
  source       = "../ecs-cluster"
  cluster_name = "${var.project_name}-master-${var.environment}"
  common_tags  = var.common_tags
}

module "agent_cluster" {
  source       = "../ecs-cluster"
  cluster_name = "${var.project_name}-agent-${var.environment}"
  common_tags  = var.common_tags
}

module "jenkins_efs" {
  source              = "../efs"
  name                = "${var.project_name}-jenkins-home-${var.environment}"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.efs.id]
  root_directory_path = "/jenkins-home"
  common_tags         = var.common_tags
}

module "alb" {
  source             = "../alb"
  name               = "${var.project_name}-jenkins-${var.environment}"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb.id]
  target_port        = 8080
  listener_port      = 80
  health_check_path  = "/login"
  common_tags        = var.common_tags
}

module "nlb" {
  source        = "../nlb"
  name          = "${var.project_name}-jnlp-${var.environment}"
  internal      = true
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  target_port   = 50000
  listener_port = 50000
  common_tags   = var.common_tags
}

##############################################################################
# Security Groups (Jenkins-specific wiring)
##############################################################################

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-${var.environment}"
  description = "Jenkins ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-alb-sg-${var.environment}" })
}

resource "aws_security_group" "master" {
  name        = "${var.project_name}-master-${var.environment}"
  description = "Jenkins master tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Web UI from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Web UI health check from NLB"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "JNLP from VPC (NLB + agents)"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-master-sg-${var.environment}" })
}

resource "aws_security_group" "agent" {
  name        = "${var.project_name}-agent-${var.environment}"
  description = "Jenkins agent tasks"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-agent-sg-${var.environment}" })
}

resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-${var.environment}"
  description = "EFS mount targets"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.master.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-efs-sg-${var.environment}" })
}

##############################################################################
# IAM Roles
##############################################################################

resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-ecs-exec-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "master_task" {
  name = "${var.project_name}-master-task-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy" "master_ecs" {
  name = "ecs-agent-management"
  role = aws_iam_role.master_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecs:RegisterTaskDefinition", "ecs:DeregisterTaskDefinition", "ecs:ListClusters", "ecs:DescribeClusters", "ecs:DescribeContainerInstances", "ecs:ListTaskDefinitions", "ecs:DescribeTaskDefinition", "ecs:DescribeTasks", "ecs:ListTasks", "ecs:RunTask", "ecs:StopTask", "ecs:ListContainerInstances", "ecs:TagResource", "ecs:ListTagsForResource"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [aws_iam_role.task_execution.arn, aws_iam_role.agent_task.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "agent_task" {
  name = "${var.project_name}-agent-task-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy" "agent_ecr" {
  name = "ecr-access"
  role = aws_iam_role.agent_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"]
      Resource = "*"
    }]
  })
}

##############################################################################
# CloudWatch Log Group
##############################################################################

resource "aws_cloudwatch_log_group" "jenkins" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  tags              = var.common_tags
}

##############################################################################
# Jenkins Master Task Definition
##############################################################################

resource "aws_ecs_task_definition" "master" {
  family                   = "${var.project_name}-master-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.master_cpu
  memory                   = var.master_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.master_task.arn

  container_definitions = jsonencode([{
    name      = "jenkins"
    image     = var.master_image
    essential = true
    command   = ["/bin/sh", "-c", "rm -rf /var/jenkins_home/war && exec /usr/local/bin/jenkins.sh"]
    portMappings = [
      { containerPort = 8080, protocol = "tcp" },
      { containerPort = 50000, protocol = "tcp" }
    ]
    mountPoints = [{
      sourceVolume  = "jenkins-home"
      containerPath = "/var/jenkins_home"
      readOnly      = false
    }]
    environment = [
      { name = "JAVA_OPTS", value = "-Djenkins.install.runSetupWizard=false -Xmx2g" },
      { name = "JENKINS_OPTS", value = "--httpPort=8080 --webroot=/var/jenkins_home/war" },
      { name = "CASC_JENKINS_CONFIG", value = "/var/jenkins_home/casc.yaml" },
      { name = "JENKINS_URL", value = "http://${module.alb.lb_dns_name}" },
      { name = "JNLP_TUNNEL", value = "${module.nlb.lb_dns_name}:50000" },
      { name = "ECS_AGENT_CLUSTER", value = module.agent_cluster.cluster_arn },
      { name = "AWS_DEFAULT_REGION", value = data.aws_region.current.name },
      { name = "SUBNETS", value = join(",", module.vpc.public_subnet_ids) },
      { name = "AGENT_SECURITY_GROUP", value = aws_security_group.agent.id },
      { name = "EXECUTION_ROLE_ARN", value = aws_iam_role.task_execution.arn },
      { name = "AGENT_TASK_ROLE_ARN", value = aws_iam_role.agent_task.arn },
      { name = "AGENT_IMAGE", value = var.agent_image },
      { name = "JENKINS_ADMIN_USER", value = var.jenkins_admin_user },
      { name = "JENKINS_ADMIN_PASSWORD", value = var.jenkins_admin_password }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.jenkins.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "master"
      }
    }
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8080/login || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 120
    }
  }])

  volume {
    name = "jenkins-home"
    efs_volume_configuration {
      file_system_id     = module.jenkins_efs.file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = module.jenkins_efs.access_point_id
        iam             = "ENABLED"
      }
    }
  }

  tags = var.common_tags
}

##############################################################################
# Jenkins Master ECS Service
##############################################################################

resource "aws_ecs_service" "master" {
  name            = "${var.project_name}-master-${var.environment}"
  cluster         = module.master_cluster.cluster_id
  task_definition = aws_ecs_task_definition.master.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnet_ids
    security_groups  = [aws_security_group.master.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "jenkins"
    container_port   = 8080
  }

  load_balancer {
    target_group_arn = module.nlb.target_group_arn
    container_name   = "jenkins"
    container_port   = 50000
  }

  health_check_grace_period_seconds = 150

  depends_on = [module.alb, module.nlb, module.jenkins_efs]

  tags = var.common_tags
}

##############################################################################
# Jenkins Agent Task Definition (template — launched dynamically by plugin)
##############################################################################

resource "aws_ecs_task_definition" "agent" {
  family                   = "${var.project_name}-agent-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.agent_cpu
  memory                   = var.agent_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.agent_task.arn

  container_definitions = jsonencode([{
    name      = "agent"
    image     = var.agent_image
    essential = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.jenkins.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "agent"
      }
    }
  }])

  tags = var.common_tags
}

data "aws_region" "current" {}
