data "aws_iam_policy" "fulls3" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role" "lambda-role" {
  name = "RetrainModel-role-xul9dosn"
  path = "/service-role/"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}
# terraform import aws_iam_role.lambda-role RetrainModel-role-xul9dosn

resource "aws_iam_policy" "lambda-basic" {
  name        = "AWSLambdaBasicExecutionRole-991f65f8-9eae-4183-a12b-9d595820615a"
  path        = "/service-role/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:us-east-1:174361135196:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-east-1:174361135196:log-group:/aws/lambda/RetrainModel:*"
            ]
        }
    ]
  })
}

resource "aws_iam_policy" "glue-trigger" {
  name        = "glue-trigger"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "glue:*",
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda-role-attach" {
  for_each = {
    "glue" = aws_iam_policy.glue-trigger.arn
    "lambda" = aws_iam_policy.lambda-basic.arn
    "s3" = data.aws_iam_policy.fulls3.arn 
  }
  role      = aws_iam_role.lambda-role.name
  policy_arn = each.value
}
