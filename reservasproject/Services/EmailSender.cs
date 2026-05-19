using System.Net;
using System.Net.Mail;

namespace reservasproject.Services
{
    public class EmailSender : IEmailSender
    {
        private readonly IConfiguration _configuration;

        public EmailSender(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public async Task SendEmailAsync(string email, string subject, string htmlMessage)
        {
            var server = _configuration["SmtpSettings:Server"];
            var port = int.Parse(_configuration["SmtpSettings:Port"]);
            var senderEmail = _configuration["SmtpSettings:SenderEmail"];
            var senderName = _configuration["SmtpSettings:SenderName"];
            var password = _configuration["SmtpSettings:Password"];

            var client = new SmtpClient(server, port)
            {
                EnableSsl = true,
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(senderEmail, password)
            };

            var mailMessage = new MailMessage
            {
                From = new MailAddress(senderEmail, senderName),
                Subject = subject,
                Body = htmlMessage,
                IsBodyHtml = true
            };
            
            mailMessage.To.Add(email);

            await client.SendMailAsync(mailMessage);
        }
    }
}
