data "archive_file" "forward_lambda_content" {
  type        = "zip"
  source_file = "lambda-function.py"
  output_path = "lambda_function_payload.zip"
}


resource "aws_lambda_function" "forward_lambda" {
  function_name    = var.forward_lambda_function_name
  role             = aws_iam_role.forward_email_lambda_role.arn
  filename         = data.archive_file.forward_lambda_content.output_path
  handler          = "lambda-function.lambda_handler"
  source_code_hash = data.archive_file.forward_lambda_content.output_base64sha256
  runtime          = "python3.9"
  timeout          = 30
  description      = "Saves a given email in S3 and forwards it to a configured recipient."

  environment {
    variables = {
      MailS3Bucket  = aws_s3_bucket.email_bucket.bucket
      MailS3Prefix  = ""
      MailSender    = "${var.forward_email_sender}@${var.incoming_domain}"
      MailRecipient = var.email_recipient
      Region        = var.ses_region
      ConfigSet     = aws_ses_configuration_set.forwarder_configuration_set.name
    }
  }

  logging_config {
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.forward_lambda_log_group.name
    application_log_level = "INFO"
    system_log_level      = "INFO"
  }

  tags = {
    Name = var.forward_lambda_function_name
  }
}

resource "aws_cloudwatch_log_group" "forward_lambda_log_group" {
  name              = "/aws/lambda/${var.forward_lambda_function_name}"
  retention_in_days = 90
  tags = {
    Name = "/aws/lambda/${var.forward_lambda_function_name}"
  }
}

resource "aws_lambda_permission" "forward_lambda_ses_permission" {
  statement_id   = "ForwardLambdaSESPermission"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.forward_lambda.function_name
  source_account = local.aws_account_id
  principal      = "ses.amazonaws.com"
}