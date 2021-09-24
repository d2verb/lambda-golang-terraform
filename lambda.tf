data "aws_iam_policy_document" "sample_lambda_assume_role" {
  statement {
    sid     = "Lambda"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "sample_lambda" {
  name               = "sample-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.sample_lambda_assume_role.json
}

resource "aws_lambda_function" "sample" {
  filename         = data.archive_file.go.output_path
  function_name    = "sample-function"
  role             = aws_iam_role.sample_lambda.arn
  handler          = "sample.exe"
  source_code_hash = data.archive_file.go.output_base64sha256
  runtime          = "go1.x"
}

resource "null_resource" "go_build" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "cd golang/src && GOOS=linux go build -o ../artifacts/sample.exe main.go"
  }
}

data "archive_file" "go" {
  depends_on  = [null_resource.go_build]
  type        = "zip"
  source_file = "golang/artifacts/sample.exe"
  output_path = "golang/artifacts/sample.zip"
}
