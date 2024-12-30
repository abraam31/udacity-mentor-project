resource "aws_iam_role" "glue-role" {
  name = "glue-s3-access"
  description = "Allows Glue to call AWS services on your behalf. "
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
    ]
  })
}
# terraform import aws_iam_role.glue-role glue-role 

data "aws_iam_policy" "cw" {
  arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

data "aws_iam_policy" "fulls3" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs-attach" {
  for_each = {
    "cw" = data.aws_iam_policy.cw.arn
    "s3" = data.aws_iam_policy.fulls3.arn 
  }
  role      = aws_iam_role.glue-role.name
  policy_arn = each.value
}

# terraform import aws_iam_policy.glue-trigger arn:aws:iam::174361135196:policy/glue-trigger
