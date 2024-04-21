resource "aws_ses_receipt_rule_set" "forwarder_rule_set" {
  rule_set_name = var.ses_receipt_rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "forwarder_rule_set_activation" {
  rule_set_name = var.ses_receipt_rule_set_name
}

resource "aws_ses_receipt_rule" "forwarder_rule" {
  name          = var.ses_receipt_rule_name
  rule_set_name = aws_ses_receipt_rule_set.forwarder_rule_set.rule_set_name
  enabled       = true
  recipients    = [var.incoming_domain, ".${var.incoming_domain}"]

  s3_action {
    bucket_name = aws_s3_bucket.email_bucket.bucket
    position    = 1
  }
  lambda_action {
    function_arn    = aws_lambda_function.forward_lambda.arn
    invocation_type = "Event"
    position        = 2
  }

  depends_on = [aws_lambda_permission.forward_lambda_ses_permission]
}

resource "aws_ses_configuration_set" "forwarder_configuration_set" {
  name = "ForwardEmailsConfigurationSet"
}

// Verification starting here
resource "aws_ses_domain_identity" "incoming_email_domain_identity" {
  domain = var.incoming_domain
}

resource "aws_ses_domain_dkim" "incoming_email_domain_identity_dkim" {
  domain = aws_ses_domain_identity.incoming_email_domain_identity.domain
}

resource "aws_route53_record" "incoming_email_dkim_record" {
  count   = 3
  name    = "${aws_ses_domain_dkim.incoming_email_domain_identity_dkim.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_dkim.incoming_email_domain_identity_dkim.domain}"
  records = ["${aws_ses_domain_dkim.incoming_email_domain_identity_dkim.dkim_tokens[count.index]}.dkim.amazonses.com"]
  type    = "CNAME"
  ttl     = 600
  zone_id = aws_route53_zone.incoming_email_domain_zone.id
}

resource "aws_route53_record" "incoming_email_dmarc_record" {
  name    = "_dmarc.${var.incoming_domain}"
  type    = "TXT"
  ttl     = 600
  zone_id = aws_route53_zone.incoming_email_domain_zone.id
  records = ["v=DMARC1; p=none;"]
}