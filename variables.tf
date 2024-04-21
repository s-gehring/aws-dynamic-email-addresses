variable "bucket_name" {
  default     = "nephelex-incoming-emails"
  type        = string
  description = "The name of the bucket to store emails in."
}

variable "forward_email_lambda_policy_name" {
  default     = "ForwardEmailLambdaPolicy"
  type        = string
  description = "The name of the policy that the forwarding lambda uses."
}

variable "forward_email_lambda_role_name" {
  default     = "ForwardEmailLambdaRole"
  type        = string
  description = "The name of the role that the forwarding lambda assumes."
}

variable "forward_lambda_function_name" {
  default     = "ForwardEmailFunction"
  type        = string
  description = "The name of the lambda function that forwards incoming emails."
}

variable "ses_receipt_rule_set_name" {
  default     = "ForwardReceiptRuleSet"
  type        = string
  description = "The name of the rule set in SES which says which emails are to be received."
}

variable "ses_receipt_rule_name" {
  default     = "ForwardReceiptRule"
  type        = string
  description = "The name of the rule in SES which says which emails are to be received."
}

variable "ses_region" {
  default     = "eu-central-1"
  type        = string
  description = "The region in which SES should receive and send your emails to/from."
}

variable "aws_region" {
  default     = "eu-central-1"
  type        = string
  description = "The region to use for the S3 backend."
}

variable "forward_email_sender" {
  default     = "forward"
  type        = string
  description = "The email account of the domain from which emails are forwarded to the final recipient. Is suffixed with the incoming_domain."
}

variable "incoming_domain" {
  type        = string
  description = "The domain whose emails are forwarded."
}

variable "email_recipient" {
  type        = string
  description = "The actual recipient of all forwarded emails."
}

