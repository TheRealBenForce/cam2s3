This project demonstrates how to use Amazon SES to store security camera alarm emails in S3. See my [blog post](https://benforce.io/2017-08-03-connecting-tenvis-cam-to-s3/) for a more detailed description. 

## Cloudformation work

Anything in this section can leverage [my CloudFormation template](https://github.com/TheRealBenForce/cam2s3).

### Make an SNS Topic
The SNS topic subscription is what is going to make up for the lackluster notification system of the native app. This is one of the easier components and there are really only two steps:

* [Make the topic.](http://docs.aws.amazon.com/sns/latest/dg/CreateTopic.html)
* [Subscribe to the topic as email.](http://docs.aws.amazon.com/sns/latest/dg/SubscribeTopic.html)

### Make a Bucket
Get your bucket started. Use [this link](http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html) as help if you are new. Then using the details below, fill in some of the specifics:

**Bucket Lifecycle -** The emails don't have much use for me. I'm mostly concerned about receiving notifications. For this reason I have a lifecycle of my bucket to delete objects in the emails folder after 30 days.  
**Bucket Logging -** Sure, why not! Let's put these in a logging folder.  
**Bucket Policy -** In order for SES to write to your bucket, you will need to configure a bucket policy. In the policy below, you will need to update the resource ARN and aws:Referer.  

```
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "GiveSESPermissionToWriteEmail",
            "Effect": "Allow",
            "Principal": {
                "Service": "ses.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::mybucket/emails/*",
            "Condition": {
                "StringEquals": {
                    "aws:Referer": "###myaccountnumber###"
                }
            }
        }
    ]
}
```

**Bucket Notification -** You want to set up S3 to send a notification to the SNS topic whenever an email occurs in the bucket. This is completed in the bucket properties of the S3 console, somewhat hidden under "events". Mine has a long crazy name because it was created in CloudFormation. I haven't found a way around that yet.

## Non CloudFormation work
Everything going forward can not be automated and must be done in the console or within the camera software.

### Verify Domain
Before SES can receive emails through Amazon's SMTP endpoint and process rules on those emails, you need to verify the ownership of the domain with Amazon. This is a pretty big process in and of itself if you registered a .io domain like me, [but I did write about it in my last post](/2017-07-26-receiving-io-certificate-validation-email\index.html).

If you are registering another top level domain (ie, .com), then the process may be much quicker for you. [This is a good link](http://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-domain-procedure.html) that should help get you started.

Don't try to shortcut it and verify an email address instead of a domain. SES email receiving needs an email address *in your verified domain*.

### SES Email Receiving
I discussed setting SES Email receiving in my last post. For this endeavor, we are taking it a step further by managing receiving email from a specific email address, that we will use exclusively for the camera.

Be sure to put this rule at the top of your rule set. If everything has worked you should see AMAZON_SES_SETUP_NOTIFICATION email in your S3 bucket.

You could set up SNS notifications here, but using the bucket satisfies the requirement and can be managed by CloudFormation.

### Get SMTP Credentials
Amazon allows any email client, whether in the AWS cloud or not, to use Amazon SMTP servers for sending and receiving mail. [This is a good page](http://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-smtp.html) to read briefly about the capabilities. Sending through Amazon SMTP does require a user within the account with the required policy and generated SMTP credentials. The SMTP credentials are not the same as access and secret key, although they look the same.

It seems *the only way* to generate SMTP credentials is to use the wizard. You can not create your own user, policy, and later connect SMTP credentials. If you go to the SES Console > SMTP Settings > Create my SMTP Credentials, a wizard will guide you through creating an IAM user with the required policy, and then generate SMTP credentials.

### Test With Powershell
This might be a good time to check to see if you can successfully send an email through the pipeline created before fiddling with the crappy camera software. You can use the PowerShell file included to run the tests. A success should show an email in your bucket. You should send to/from email addresses you have already verified.

A failure will help you understand where the problem is. For instance an error like this indicates you are leaving your network and communicating with Amazon and that there may be a problem with your SMTP credentials.

```
Exception calling "Send" with "1" argument(s): "The SMTP server requires a secure connection or the client was not authenticated. The server response was: Authentication required"
At C:\Users\Ben\repos\Send-AmazonSmtpEmail.ps1:54 char:5
+     $SMTPClient.Send($SMTPMessage)
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : SmtpException
```

An error like this is because your to/from email addresses have not been verified:

```
Exception calling "Send" with "1" argument(s): "Transaction failed. The server response was: Message rejected: Email address is not verified. The following identities failed the check in region US-EAST-1: your-momma@gmail.com"
At C:\Users\Ben\repos\Send-AmazonSmtpEmail.ps1:52 char:5
+     $SMTPClient.Send($SMTPMessage)
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : SmtpException
```


### Configure the Camera
Getting good at working with AWS services means getting good at using their documentation. This [page here](http://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-smtp.html) and [this page](http://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-connect.html) have some good info on setting up your email client, in this case a camera.

Once you log in to your camera web portal, you'll need to access the administrative area where you configure email. Once there, focus on:

* [An SMTP endpoint](http://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-connect.html) closest to the camera. One of these will do the trick.
* STARTTLS
* Port 587. I'm on Windows 10 with a Verizon Fios Quantum Gateway router. Port 25 was not working for me and I had limited access to router logs. The camera logs were also no good. I may have gotten lucky here.
* To/from email. No reason they can't be the same.
* SMTP credentials.

Fill this stuff in, then click the test button and you should be in business!
