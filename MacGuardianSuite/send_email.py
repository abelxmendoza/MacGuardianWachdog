#!/usr/bin/env python3
"""
Email Sender for MacGuardian Suite
Uses SMTP to send emails (works with Gmail, Outlook, etc.)
"""

import smtplib
import sys
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import argparse

def send_email(to_email, subject, body, html_body=None, attachment_path=None, smtp_config=None):
    """
    Send email using SMTP
    
    Args:
        to_email: Recipient email address
        subject: Email subject
        body: Plain text body
        html_body: Optional HTML body
        attachment_path: Optional file path to attach
        smtp_config: Optional dict with SMTP settings
    """
    
    # Default SMTP config (Gmail)
    default_config = {
        'smtp_server': 'smtp.gmail.com',
        'smtp_port': 587,
        'use_tls': True,
        'username': None,
        'password': None
    }
    
    if smtp_config:
        default_config.update(smtp_config)
    
    config = default_config
    
    # Try to get credentials from environment or config file
    if not config['username']:
        config['username'] = os.environ.get('SMTP_USERNAME') or os.environ.get('EMAIL_USERNAME')
    if not config['password']:
        config['password'] = os.environ.get('SMTP_PASSWORD') or os.environ.get('EMAIL_PASSWORD') or os.environ.get('GMAIL_APP_PASSWORD')
    
    # If no credentials, try to use system mail (fallback)
    if not config['username'] or not config['password']:
        print("⚠️  SMTP credentials not configured. Using system mail as fallback.")
        print("   To use SMTP, set environment variables:")
        print("   export SMTP_USERNAME='your-email@gmail.com'")
        print("   export SMTP_PASSWORD='your-app-password'")
        return False
    
    try:
        # Create message
        if html_body:
            msg = MIMEMultipart('alternative')
            msg.attach(MIMEText(body, 'plain'))
            msg.attach(MIMEText(html_body, 'html'))
        else:
            msg = MIMEText(body)
        
        msg['Subject'] = subject
        msg['From'] = config['username']
        msg['To'] = to_email
        
        # Add attachment if provided
        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path, 'rb') as f:
                part = MIMEBase('application', 'octet-stream')
                part.set_payload(f.read())
                encoders.encode_base64(part)
                part.add_header(
                    'Content-Disposition',
                    f'attachment; filename= {os.path.basename(attachment_path)}'
                )
                if isinstance(msg, MIMEMultipart):
                    msg.attach(part)
        
        # Connect to SMTP server
        if config['use_tls']:
            server = smtplib.SMTP(config['smtp_server'], config['smtp_port'])
            server.starttls()
        else:
            server = smtplib.SMTP_SSL(config['smtp_server'], config['smtp_port'])
        
        server.login(config['username'], config['password'])
        server.send_message(msg)
        server.quit()
        
        print(f"✅ Email sent successfully to {to_email}")
        return True
        
    except smtplib.SMTPAuthenticationError:
        print("❌ Authentication failed. Check your username and password.")
        print("   For Gmail, use an App Password (not your regular password)")
        return False
    except smtplib.SMTPException as e:
        print(f"❌ SMTP error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error sending email: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Send email via SMTP')
    parser.add_argument('to_email', help='Recipient email address')
    parser.add_argument('subject', help='Email subject')
    parser.add_argument('body', help='Email body')
    parser.add_argument('--html', help='HTML body (optional)')
    parser.add_argument('--attachment', help='Path to attachment file')
    parser.add_argument('--smtp-server', default='smtp.gmail.com', help='SMTP server')
    parser.add_argument('--smtp-port', type=int, default=587, help='SMTP port')
    parser.add_argument('--username', help='SMTP username')
    parser.add_argument('--password', help='SMTP password')
    
    args = parser.parse_args()
    
    smtp_config = {
        'smtp_server': args.smtp_server,
        'smtp_port': args.smtp_port,
        'username': args.username,
        'password': args.password
    }
    
    success = send_email(
        args.to_email,
        args.subject,
        args.body,
        html_body=args.html,
        attachment_path=args.attachment,
        smtp_config=smtp_config
    )
    
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()

