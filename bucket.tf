resource "aws_s3_bucket" "email_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}


resource "aws_s3_bucket_policy" "email_bucket_policy_association" {
  bucket = aws_s3_bucket.email_bucket.id
  policy = data.aws_iam_policy_document.email_bucket_policy.json
}

data "aws_iam_policy_document" "email_bucket_policy" {
  statement {
    principals {
      identifiers = ["ses.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.email_bucket.arn}/*"]
    condition {
      test     = "StringEquals"
      values   = [local.aws_account_id]
      variable = "aws:Referer"
    }
  }

}

