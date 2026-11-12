---
id: DM-Mail
title: Email Message, SMTP Configuration, and Typed SMTP Error Model
status: approved
domain: MAIL
implements: [FR-MAIL-001]
verified_by: [TS-MAIL-001]
---
# DM-Mail — Email Message, SMTP Configuration, and Typed SMTP Error Model

## Overview
Defines the RFC 5322 email message (`MailMessage`, `MailResult`) and RFC 5321/6409 SMTP client configuration and result (`SmtpConfig`, `SmtpError`, `SmtpResult`) ADTs in `src/main/ridgun/lib/mail.ridgun`.

## Algebraic Data Types
- `MailMessage`: `from_addr`, `to_addrs`, `reply_to_addr`, `subject_line`, `text_body`, `html_body`, `message_id`, `date_sec`.
- `MailResult`: `MailOk String | MailErr String`.
- `SmtpConfig`: `host`, `port`, `smtp_user`, `smtp_password`, `auth_method`, `timeout_ms`, `tls_config`.
- `SmtpError`: `SmtpConnectionError String | SmtpTlsError String | SmtpAuthError Int String | SmtpRejectedRecipient Int String | SmtpTemporaryError Int String | SmtpProtocolError Int String | SmtpInvalidMessage String`.
- `SmtpResult`: `SmtpOk Int String | SmtpErr SmtpError`.
