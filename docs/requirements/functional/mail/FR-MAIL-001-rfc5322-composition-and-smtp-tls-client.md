---
id: FR-MAIL-001
title: Provide RFC 5322 Email Composition and RFC 5321/6409/8314/3207/4954 SMTP Client over TLS Library
type: functional
status: implemented
priority: must
domain: MAIL
depends_on: [FR-TLS-001, FR-SOCK-004, FR-CODEC-001, FR-TIME-001]
related: [API-MAIL-001, DM-Mail, VUL-INJ-002, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-MAIL-001]
---
# FR-MAIL-001 — Provide RFC 5322 Email Composition and RFC 5321/6409/8314/3207/4954 SMTP Client over TLS Library

## Statement
The `mail` lib (`src/main/ridgun/lib/mail.rg`) SHALL provide a 100% pure-Ridgun RFC 5322 email message builder and renderer (`mail message`, `mail with html`, `mail with reply to`, `mail add to`, `mail render`) with strict CRLF header-injection rejection, RFC 2047 UTF-8 `=?UTF-8?B?...?=` encoding for non-ASCII subjects and display names, `local@domain` mailbox validation, `text/plain; charset=UTF-8` and `multipart/alternative` MIME bodies with $\le 998$-byte lines and dot-stuffing, and an RFC 5321/6409/8314/3207/4954 SMTP submission client (`smtp config`, `smtp send`) supporting implicit TLS on port 465 and mandatory `STARTTLS` on port 587 with `AUTH PLAIN` and `AUTH LOGIN` exclusively after TLS is established.

## Rationale
Solstice (`ridgun.com`) needs to send signed single-use account verification emails upon registration and password reset emails through an SMTP provider in pure Ridgun without invoking `sendmail` or any external process.

## Acceptance criteria
- AC1: Given a `MailMessage`, when `mail render msg` is called, then it:
  - Rejects any `From`, `To`, `Reply-To`, `Subject`, or `Message-ID` header value or mailbox address containing `\r` (`CR`) or `\n` (`LF`), returning `MailErr`.
  - Validates `local@domain` mailbox syntax per RFC 5321 §4.1.2.
  - Encodes non-ASCII `Subject` values and display names using RFC 2047 `=?UTF-8?B?...?=`.
  - Emits `From`, `To`, optional `Reply-To`, `Subject`, `Date` (RFC 5322 §3.3), `Message-ID` (`<random@sender_domain>`), `MIME-Version: 1.0`, and `text/plain; charset=UTF-8` (or `multipart/alternative` when `mail with html` is set) with `CRLF` line endings, lines $\le 998$ bytes, and RFC 5321 §4.5.2 dot-stuffing on body lines starting with `.`.
- AC2: Given an `SmtpConfig` and a `MailMessage`, when `smtp send cfg msg` runs against a local Ridgun test SMTP server, then it:
  - Executes the full `EHLO` -> (`STARTTLS` -> TLS handshake -> `EHLO` on port 587, or implicit TLS -> `EHLO` on port 465) -> `AUTH PLAIN` / `AUTH LOGIN` -> `MAIL FROM` -> `RCPT TO` (supporting multiple recipients) -> `DATA` -> `QUIT` conversation and parses multi-line SMTP replies.
  - Fails immediately with `SmtpErr (SmtpTlsError ...)` if a non-implicit-TLS server does not advertise `STARTTLS`, never continuing in cleartext.
  - Never transmits `AUTH PLAIN` or `AUTH LOGIN` credentials unless TLS is active.
  - Distinguishes connection errors (`SmtpConnectionError`), TLS errors (`SmtpTlsError`), authentication errors (`SmtpAuthError`), rejected recipients (`5xx`, `SmtpRejectedRecipient`), and temporary failures (`4xx`, `SmtpTemporaryError`).
- AC3: Given a real or TLS-enabled SMTP submission server, `smtp send` completes the TLS handshake, authenticates, and delivers the rendered RFC 5322 message.
