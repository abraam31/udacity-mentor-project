resource "aws_ecs_cluster" "fraudapi-cluster" {
  name = "fraudapi"

  service_connect_defaults {
    namespace = "arn:aws:servicediscovery:us-east-1:174361135196:namespace/ns-h4bozse2gwn6ple6"
  }
}

resource "aws_ecs_task_definition" "fraudapi-definition" {
  family = "fraudapi"
  network_mode = "awsvpc"
  cpu = "1024"
  memory = "3072"
  execution_role_arn = "arn:aws:iam::174361135196:role/ecsTaskExecutionRole" 
  task_role_arn = "arn:aws:iam::174361135196:role/ecsTaskExecutionRole"
  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "174361135196.dkr.ecr.us-east-1.amazonaws.com/fraud_api:latest"
      essential = true
      logConfiguration = {
          logDriver     = "awslogs"
          options       = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/fraudapi"
            awslogs-region        = "us-east-1"
            awslogs-stream-prefix = "ecs"
            max-buffer-size       = "25m"
            mode                  = "non-blocking"
          }
      }
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          appProtocol = "http"
          name = "http"
          protocol = "tcp"
        }
      ]
      environment      = []
      environmentFiles = []
      mountPoints      = []
      systemControls   = []
      ulimits          = []
    }
  ])

  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }

  requires_compatibilities = ["FARGATE"]
}

resource "aws_lb_target_group" "fraudapi-tg" {
  name     = "ecs-fraudapi"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0db448dd8e0ced684"
  target_type = "ip"
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,404"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 8
}
}

resource "aws_ecs_service" "fraudapi-svc" {
  name            = "fraudapi"
  cluster         = aws_ecs_cluster.fraudapi-cluster.id
  task_definition = aws_ecs_task_definition.fraudapi-definition.arn
  availability_zone_rebalancing = "ENABLED"
  enable_ecs_managed_tags = true
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.fraudapi-tg.arn
    container_name   = "api"
    container_port   = 8000
  }

  capacity_provider_strategy { 
     base              = 0
     capacity_provider = "FARGATE"
     weight            = 1
  }

 network_configuration {
    assign_public_ip = true
    security_groups  = [
      "sg-08fb471cefeb063ce",
      ]
    subnets = [
      "subnet-02c5705fe27b6a25f",
      "subnet-06efe3f54330428c1",
      "subnet-0c9b76c7bb5e9910c",
      "subnet-0d021f5a40a7fcf84",
      "subnet-0d7378cdce03577e4",
      "subnet-0d89d079c263cca51",
      ]
    }

  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
}
