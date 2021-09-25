# ロググループ
resource "aws_cloudwatch_log_group" "sample" {
  name = "/sample/ecs"
}

# ロール
## task execution role
data "aws_iam_policy_document" "ecs_tasks_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_tasks_execution_role" {
  name               = "sample-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_execution_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS
resource "aws_ecs_cluster" "sample" {
  name = "sample-cluster"
}

resource "aws_ecs_task_definition" "sample" {
  family                   = "sample"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "sample"
      image     = "hello-world:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "sample"
          awslogs-group         = "/sample/ecs"
        }
      }
    }
  ])
}

# VPC
resource "aws_vpc" "sample" {
  cidr_block = "10.0.0.0/16"
}

# サブネット
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.sample.id
  availability_zone       = "ap-northeast-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "sample" {
  vpc_id = aws_vpc.sample.id
}

# ルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.sample.id
}

resource "aws_route" "public" {
  gateway_id             = aws_internet_gateway.sample.id
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# セキュリティグループ
resource "aws_security_group" "ecs" {
  name   = "sample-ecs-sg"
  vpc_id = aws_vpc.sample.id
}

resource "aws_security_group_rule" "in" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
}

# アウトプット
output "task_definition" {
  value = aws_ecs_task_definition.sample.arn
}

output "aws_subnet" {
  value = aws_subnet.public.id
}

output "aws_security_group" {
  value = aws_security_group.ecs.id
}
