---
id: API-MAIL-001
title: Public API Contract for mail.rg
status: approved
domain: MAIL
implements: [FR-MAIL-001]
verified_by: [TS-MAIL-001]
---
# API-MAIL-001 — Public API Contract for `mail.rg`

## Module
`src/main/ridgun/lib/mail.rg` (`module :: mail`)

## Types
- `type MailMessage = from_addr: String, to_addrs: [String], reply_to_addr: String, subject_line: String, text_body: String, html_body: String, message_id: String, date_sec: Int`
- `type MailResult = MailOk String | MailErr String`
- `type SmtpConfig = host: String, port: Int, smtp_user: String, smtp_password: String, auth_method: String, timeout_ms: Int, tls_config: TlsConfig`
- `type SmtpError = SmtpConnectionError String | SmtpTlsError String | SmtpAuthError Int String | SmtpRejectedRecipient Int String | SmtpTemporaryError Int String | SmtpProtocolError Int String | SmtpInvalidMessage String`
- `type SmtpResult = SmtpOk Int String | SmtpErr SmtpError`

## Public Functions
- `fn :: mail message String String String String => MailMessage`
- `fn :: mail with html MailMessage String => MailMessage`
- `fn :: mail with reply to MailMessage String => MailMessage`
- `fn :: mail add to MailMessage String => MailMessage`
- `fn :: mail with to MailMessage [String] => MailMessage`
- `fn :: mail with date MailMessage Int => MailMessage`
- `fn :: mail with message id MailMessage String => MailMessage`
- `fn :: mail valid address String => Bool`
- `fn :: mail encode rfc2047 String => String`
- `fn :: mail format date Int => String`
- `fn :: smtp dot stuff String => String`
- `fn :: mail render MailMessage => MailResult`
- `fn :: mail is ok MailResult => Bool`
- `fn :: mail unwrap MailResult => String`
- `fn :: mail error MailResult => String`
- `fn :: smtp config String Int String String => SmtpConfig`
- `fn :: smtp with tls SmtpConfig TlsConfig => SmtpConfig`
- `fn :: smtp with auth SmtpConfig String => SmtpConfig`
- `fn :: smtp with timeout SmtpConfig Int => SmtpConfig`
- `fn :: smtp parse response String => Int [String] String`
- `fn :: smtp send SmtpConfig MailMessage => SmtpResult`
- `fn :: smtp is ok SmtpResult => Bool`
- `fn :: smtp is retryable SmtpResult => Bool`
- `fn :: smtp error kind SmtpResult => String`
- `fn :: smtp error reason SmtpResult => String`
