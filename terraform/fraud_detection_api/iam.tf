resource "aws_iam_role" "ecs-service" {
  name = "ecsTaskExecutionRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy" "ecstask" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "fulls3" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs-attach" {
  for_each = {
    "ecs" = data.aws_iam_policy.ecstask.arn
    "s3" = data.aws_iam_policy.fulls3.arn 
  }
  role      = aws_iam_role.ecs-service.name
  policy_arn = each.value
}

# terraform import aws_iam_policy.glue-trigger arn:aws:iam::174361135196:policy/glue-trigger
# terraform import aws_iam_role.ecs-service ecsTaskExecutionRole