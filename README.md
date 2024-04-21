# Dynamic Email Addresses with AWS

This is a complete collection of resources you need to have unlimited
email addresses of your own (sub-)domain that all get forwarded to a
centralized email and also archived on S3.

Allocates a domain (say `awesome-cheesecake.com`) and archives and redirects all emails to this domain to your private 
email address. So you can use `info@awesome-cheesecake.com`, `spam@awesome-cheesecake.com`, 
`xyz-abc.123-456@awesome-cheesecake.com` or whatever without any more configuration. Perfect for throwaway addresses you
might need later or for web services that don't accept throwaway addresses.

## Background

This is a proof-of-concept for how you can configure AWS to receive and compute emails
and afterward forward it to another email address, which is external to AWS. This closely
follows the
guide "[Forward Incoming Email to an External Destination](https://aws.amazon.com/de/blogs/messaging-and-targeting/forward-incoming-email-to-an-external-destination/)"
from 2019. However,
this solution is bundled together in one terraform module. It works, even if your AWS account is still in sandbox, and it is not necessary (nor advisable) to take it out of sandbox mode for this purpose. If you want to use this solution with your account being in sandbox, remember to verify your [receiving email identity in SES](https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html). The domain and therefore the sending email address is verified automatically.

This solution is relatively cheap, but can get out of hand quickly, when a malicious party tries to incur as much cost as possible and your account is not in the SES sandbox anymore and has a high email limit. Beware of this.

## Architecture

The finished architecture can be found in
the [original article by AWS](https://aws.amazon.com/de/blogs/messaging-and-targeting/forward-incoming-email-to-an-external-destination/):

> ![Email-Forwarder Architecture](./documentation/Email-Forwarder.png?raw=true)
>
> The following actions occur in this solution:
> 1. A new email is sent from an external sender to your domain. Amazon SES handles the incoming email for your domain.
> 2. An Amazon SES receipt rule saves the incoming message in an S3 bucket.
> 3. An Amazon SES receipt rule triggers the execution of a Lambda function.
> 4. The Lambda function retrieves the message content from S3, and then creates a new message and sends it to Amazon
     SES.
> 5. Amazon SES sends the message to the destination server.

Setting it up from an infrastructure perspective is a little more sophisticated.

![Email-Forwarder Infrastructure Setup](./documentation/Setup-Infrastructure.svg?raw=true)

Here you can see what the terraform setup does:

1. Register your domain with Route53. If you have already registered
   it, [terraform will adopt it instead](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53domains_registered_domain).
   **Registering domains will generally incur costs.**
2. Creating a new hosted zone for the domain. Be sure to import yours instead if you have already registered your domain
   before with Route53 as this will automatically create a new hosted zone.
3. Adding an [MX-record to Route53](https://docs.aws.amazon.com/ses/latest/dg/receiving-email-mx-record.html) that
   enables AWS to receive messages. This MX-entry is region-aware.
4. Create a new bucket for archiving emails.
5. Adding a bucket policy to the newly created bucket
   to [enable SES to put objects in it](https://docs.aws.amazon.com/ses/latest/dg/receiving-email-permissions.html#receiving-email-permissions-s3).
6. Create an IAM policy for lambda that lets it
    - [Create and write to log streams](https://docs.aws.amazon.com/lambda/latest/operatorguide/access-logs.html) (of a
      specific log group)
    - [Send emails](https://docs.aws.amazon.com/ses/latest/dg/control-user-access.html#iam-and-ses-examples-email-sending-actions)
      via SES
    - Get objects from the created email bucket.
7. Create an IAM role with this policy, adding
   a [generic "Assume Role" policy for AWS lambda](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html#permissions-executionrole-api).
8. Create the actual lambda function
9. Create a log group for lambda to write in.
10. Create a "domain identity" for your new domain and create DNS entries
    for [Easy DKIM](https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dkim-easy.html) & [DMARC](https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dmarc.html).
11. Create a receipt rule set (and set it to active), which just catches all emails to this domain and subdomains.
12. Create a new configuration set for sending emails.

## Usage

You need [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) and the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) installed and ready to go. This especially means having the AWS CLI authorized with the AWS account you want to use.

You just install the given terraform module within your AWS account:

1. Revisit the default from [the configuration file](./variables.tf), change if necessary, create a .tfvars file or use command line arguments.
2. Execute `terraform apply`
3. Give answers for the remaining mandatory parameters when asked
4. Give it some time to propagate DNS entries and register your domain (if necessary)
5. Enjoy your unlimited email addresses
6. (optional) Add any logic you want to the [Lambda function](./lambda-function.py) to filter emails or do anything else with it.
7. (optional) Configure an S3 lifecycle for emails, for example to archive them after no access for a month or even delete them, depending on your use case.

## Costs

Since all resources are inside AWS, those might incur costs after, and even before your free tier expires.  
All prices are taken at the time of writing and might change.

- Registering and re-registering your domain. AWS takes an [annual fee](https://aws.amazon.com/de/route53/pricing/) for
  holding your
  domain ([direct link to PDF](https://d32ze2gidvkk54.cloudfront.net/Amazon_Route_53_Domain_Registration_Pricing_20140731.pdf)).
- [Hosted zones](https://aws.amazon.com/de/route53/pricing/) costs about $0.50 each month. You pay extra for more than
  10,000 records, but this is negligible in this case.
- [S3 storage](https://aws.amazon.com/de/s3/pricing/) costs around $0,023 per GB per
  month. [Gmail provides 15 GB](https://support.google.com/mail/answer/9312312?hl=en) (and shares it with Google Drive
  and Google Photos), so this amount of emails would lead to `15GB * $0,023/GB = $0,345` cost per month for storage.
- [AWS Lambda](https://aws.amazon.com/de/lambda/pricing/) prices with memory allocation size and runtime and also number
  of invocations. For simplicity say that we get less than 1 Mio. emails a month. The lambda is configured to take 128
  MB of memory and runs around 3,300ms on a near-empty email (which increases as the email gets larger), but at most
  30,000ms. AWS takes `C = $0.0000166667 /GB /s`, so expect costs per email of `C * 3.300s * 0.128GB ≈ $0.00000704` up
  to `C * 30.0s * 0.128GB ≈ $0.000064`, meaning that AWS lambda will incur up to $0.064 for every 1,000 emails, ignoring
  the
  permanent [monthly free tier](https://aws.amazon.com/de/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=categories%23serverless&all-free-tier.q=lambda&all-free-tier.q_operator=AND).
- [AWS Cloudwatch](https://aws.amazon.com/de/cloudwatch/pricing/) costs about $0.50 per GB ingested logs and $0.03 per
  GB stored per month. Lambda should send a lot less than 1kB per invocation to cloudwatch. With an assumed less than 1
  Mio. emails a month, this leads to less than a GB ingestion and therefore less than $0.50 ingestion cost. Retention of
  the logs can be changed and are set to 90 days, meaning at most three months of logs will be stored at the same time.
  This leads to a maximum cost of about `$0.50 + $0.03 * 3 = $0.59` a month.
- [AWS SimpleEmailService](https://aws.amazon.com/de/ses/pricing/) incurs two costs, both because of incoming and
  outgoing emails:
    - **Incoming**: SES costs $0.10 per 1,000 incoming emails, but
      additional [$0.09 for each 1,000 blocks of 256kB](https://aws.amazon.com/de/ses/pricing/#Pricing_details) of
      email (rounded down). This makes calculating the actual costs hard. Assuming 5,000 emails a month, all of them
      being [as large as possible](https://aws.amazon.com/de/about-aws/whats-new/2021/09/amazon-ses-emails-message-40mb/) (
      40MB), this would equate
      to `$0.10 / 1,000 * 5,000 + $0.09 / 1,000 / 256kB * 40MB * 5,000 = $0.50 + $70.3125 = $70.8125`. Using a more
      average approximation of email sizes of around 500kB, we get around `$0.50 + 0.879 = $1.329` per 5,000 emails.
    - **Outgoing**: SES costs $0.10 per 1,000 outgoing emails, but additional $0.12 per GB attachment (which in our case
      contain the complete incoming emails). Taking the upper limit of 15GB we took at the S3 approximation, and assume
      5,000 emails a month, we get costs of `$0.10 / 1,000 * 5,000 + 15GB * $0.12/GB = $0.50 + $1.80 = $2.30`.

The following table is an assortment of estimated costs for different use cases. You can also use the [provided
calculator](./documentation/pricing.xlsx) to estimate your own costs. Keep in mind, that those tools don't have any warranty and might be incorrect.
For a more sophisticated cost estimation use the [AWS Pricing Calculator](https://calculator.aws/#/).

| # Emails p. m. | Avg. Size | Monthly Costs<sup>*</sup> | Comment                                              |
|----------------|-----------|---------------------------|------------------------------------------------------|
| 20             | 75kB      | $ 0.51                    | Avg. Size<sup>1)</sup>                               |
| 20             | 10MB      | $ 0.87                    | Normal Max.<sup>4)</sup>                             |
| 20             | 40MB      | $ 1.99                    | Max. Size<sup>3)</sup>                               |
| 200            | 75kB      | $ 0.57                    | Avg. Size<sup>1)</sup>                               |
| 200            | 10MB      | $ 4.24                    | Normal Max.<sup>4)</sup>                             |
| 200            | 40MB      | $ 15.35                   | Max. Size<sup>3)</sup>                               |
| 1,200          | 75kB      | $ 0.91                    | Avg. Count<sup>2)</sup><br/>Avg. Size<sup>1)</sup>   |
| 1,200          | 10MB      | $ 22,96                   | Avg. Count<sup>2)</sup><br/>Normal Max.<sup>4)</sup> |
| 1,200          | 40MB      | $ 89.62                   | Avg. Count<sup>2)</sup><br/>Max. Size<sup>3)</sup>   |
| 10,000         | 75kB      | $ 3.89                    | Avg. Size<sup>1)</sup>                               |
| 10,000         | 10MB      | $ 187.66                  | Normal Max.<sup>4)</sup>                             | 
| 10,000         | 40MB      | $ 743.13                  | Max. Size<sup>3)</sup>                               |

<sup>* not including domain costs, which vary widely</sup>  
<sup>1) ["Why Are Email Files so Large" by H. Tschabitscher in Lifewire](https://www.lifewire.com/what-is-the-average-size-of-an-email-message-1171208)</sup>    
<sup>2) ["How Many Emails Are Sent Per Day In 2024" by J. Norquay in Properity Media](https://prosperitymedia.com.au/how-many-emails-are-sent-per-day-in-2024/)</sup>      
<sup>3) ["Amazon SES now supports emails with a message size of up to 40MB" by AWS](https://aws.amazon.com/de/about-aws/whats-new/2021/09/amazon-ses-emails-message-40mb/)</sup>      
<sup>4) ["Optimizing Email Size Limits" by Mailslurp](https://www.mailslurp.com/guides/email-size-limits/)
