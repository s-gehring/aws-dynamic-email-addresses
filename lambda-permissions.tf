data "aws_iam_policy_document" "forward_email_lambda_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.forward_lambda_log_group.arn}:*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "ses:SendRawEmail"]
    resources = [
      "${aws_s3_bucket.email_bucket.arn}/*",
      aws_ses_domain_identity.incoming_email_domain_identity.arn,
      "arn:aws:ses:${var.ses_region}:${local.aws_account_id}:identity/${var.email_recipient}",
      aws_ses_configuration_set.forwarder_configuration_set.arn
    ]
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}


resource "aws_iam_policy" "forward_email_lambda_policy" {
  policy      = data.aws_iam_policy_document.forward_email_lambda_policy.json
  name        = var.forward_email_lambda_policy_name
  description = "The policy that is used by the email forwarding lambda function."
}

resource "aws_iam_role" "forward_email_lambda_role" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  name               = var.forward_email_lambda_role_name
  tags = {
    Name = var.forward_email_lambda_role_name
  }
  managed_policy_arns = [
    aws_iam_policy.forward_email_lambda_policy.arn
  ]
}
