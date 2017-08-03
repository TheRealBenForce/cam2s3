<#
.Synopsis
   Tests sending emails using Amazon SMTP.
.DESCRIPTION
   Tests sending emails using Amazon SMTP.
.EXAMPLE
   Test-CameraEmail -EmailTo cam@benforce.io -EmailFrom cam@benforce.io -user AKIAIVI5SDQCNK6T7QMQ -password $mypassword
#>
function Test-CameraEmail
{
    Param
    (
        
        # Who is sending the email
        $EmailTo,

        # Where is it going
        $EmailFrom,

        # Email subject
        $Subject = "Test subject",

        # Email body
        $Body = "Test body",

        # SMTP Server
        $SMTPServer = "email-smtp.us-east-1.amazonaws.com",

        # Attachment
        $filenameAndPath = $null,

        # Port
        $port = '587',

        # SMTP User
        $user = '',

        # SMTP Password
        $password = ''

    )


    $SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom,$EmailTo,$Subject,$Body)
    if ($attachment -ne $null) {
        $SMTPattachment = New-Object System.Net.Mail.Attachment($attachment)
        $SMTPMessage.Attachments.Add($STMPattachment)
    }
    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, $port) 
    $SMTPClient.EnableSsl = $true 
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($user, $Password); 
    $SMTPClient.Send($SMTPMessage)
    Remove-Variable -Name SMTPClient
    Remove-Variable -Name Password

}


