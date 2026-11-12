---
id: TS-MAIL-001
title: Verify RFC 5322 Message Rendering, CRLF Injection Rejection, RFC 2047 Encoding, and SMTP over TLS Conversation
status: automated
level: functional
domain: MAIL
covers: [FR-MAIL-001, API-MAIL-001, DM-Mail]
automated_in: [src/test/ridgun/test mail.ridgun]
---
# TS-MAIL-001 — Verify RFC 5322 Message Rendering, CRLF Injection Rejection, RFC 2047 Encoding, and SMTP over TLS Conversation

## Scope
Verifies `src/main/ridgun/lib/mail.ridgun` across RFC 5322 composition (`mail message`, `mail with html`, `mail with reply to`, `mail add to`, `mail render`), CRLF header-injection rejection, RFC 2047 UTF-8 `=?UTF-8?B?...?=` subject/name encoding, `CRLF` and dot-stuffing, and `smtp send` against a local Ridgun SMTP test server (full conversation, mandatory `STARTTLS` enforcement, refusal to send `AUTH` in cleartext, and typed `4xx`/`5xx`/auth errors).

## Test Cases
1. **`mail render` Composition, RFC 2047, CRLF & Dot-Stuffing, and CRLF Injection Rejection (`AC1`)**:
   - Rejects `\r` or `\n` in `From`, `To`, `Reply-To`, `Subject`, or `Message-ID`.
   - Encodes accented UTF-8 subjects and display names per RFC 2047 (`=?UTF-8?B?...?=`).
   - Validates `local@domain` addresses, formats RFC 5322 `Date` and `Message-ID`, supports `text/plain` and `multipart/alternative` HTML, emits `CRLF`, and applies dot-stuffing to lines starting with `.`.
2. **`smtp send` Against Local Ridgun Test Server (`AC2`, `AC3`)**:
   - Completes full SMTP submission over TLS (`EHLO`, `STARTTLS`, TLS upgrade, `EHLO`, `AUTH PLAIN` / `AUTH LOGIN`, `MAIL FROM`, `RCPT TO`, `DATA` with dot-stuffing, `QUIT`).
   - Fails with `SmtpErr (SmtpTlsError ...)` if the server on port 587 does not offer `STARTTLS`, and never sends `AUTH` credentials in cleartext.
   - Maps `535` to `SmtpAuthError`, `550` on `RCPT TO` to `SmtpRejectedRecipient`, and `450`/`421` to retryable `SmtpTemporaryError`.
