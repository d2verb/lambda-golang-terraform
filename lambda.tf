# ロール
data "aws_iam_policy_document" "lambda_assume_role" {
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

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecs:RunTask"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "sample-lambda-policy"
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_iam_role" "lambda" {
  name               = "sample-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Lambda 関数
resource "aws_lambda_function" "sample" {
  filename         = data.archive_file.go.output_path
  function_name    = "sample-function"
  role             = aws_iam_role.lambda.arn
  handler          = "sample.exe"
  source_code_hash = data.archive_file.go.output_base64sha256
  runtime          = "go1.x"
}

# ビルド ＆ アーカイブ
resource "null_resource" "go_build" {
  triggers = {
    always_run = timestamp()
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
