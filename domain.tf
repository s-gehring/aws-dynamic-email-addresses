resource "aws_route53domains_registered_domain" "incoming_email_domain" {
  domain_name   = var.incoming_domain
  transfer_lock = false
}

resource "aws_route53_zone" "incoming_email_domain_zone" {
  name = var.incoming_domain
}

resource "aws_route53_record" "incoming_email_mx_record" {
  name    = var.incoming_domain
  type    = "MX"
  ttl     = 300
  zone_id = aws_route53_zone.incoming_email_domain_zone.id
  records = ["10 inbound-smtp.${var.ses_region}.amazonaws.com"]
}

