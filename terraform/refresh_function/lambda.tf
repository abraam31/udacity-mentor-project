data "template_file" "temp_file" {
    template = "${file("../refresh_function.py")}"
}

resource "local_file" "archive_prep" {
    filename = "${path.module}/temp/lambda_function.py"
    content = "${data.template_file.temp_file.rendered}"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir = "${path.module}/temp"
  output_path = "lambda_function_payload.zip"
  depends_on = [ 
    local_file.archive_prep
  ]
}

resource "aws_lambda_function" "RetrainModel" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "RetrainModel"
  role          = "arn:aws:iam::174361135196:role/service-role/RetrainModel-role-xul9dosn"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  source_code_hash = data.archive_file.lambda.output_base64sha256
  # source_code_hash = data.archive_file.lambda.output_base64sha256
}

