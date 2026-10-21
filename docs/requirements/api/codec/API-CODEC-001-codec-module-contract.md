---
id: API-CODEC-001
title: Public module contract for codec (codec.rglib / libcodec.so)
status: approved
implements: [FR-CODEC-001]
auth: none
---
# API-CODEC-001 — Public module contract for `codec` (`codec.rg`)

## Request
- Imported via `import codec`.
- RFC 4648 Hex, Base64 & Base64url:
  - `hex encode String => String`, `hex decode String => String`, `is valid hex String => Bool`
  - `base64 encode String => String`, `base64 decode String => String`, `is valid base64 String => Bool`
  - `base64url encode String => String`, `base64url decode String => String`
- RFC 3986 URL Percent-Encoding & Query Strings:
  - `url encode String => String`, `url decode String => String`
  - `query string encode [(String, String)] => String`, `query string decode String => [(String, String)]`
- RFC 8259 Lightweight JSON:
  - `json escape String => String`, `json unescape String => String`, `json quote String => String`, `json int Int => String`, `json bool Bool => String`, `json null => String`
  - `json array [String] => String`, `json object [(String, String)] => String`, `json str object [(String, String)] => String`
  - `json get str String String => String`, `json get int String String Int => Int`, `json get bool String String Bool => Bool`

## Responses
| Code | When | Body |
|---|---|---|
| `String` / `[(String, String)]` | Valid encoding, decoding, or JSON extraction | Encoded/decoded string, query pairs, or extracted field value |
| `""` / `False` | Invalid hex/Base64 input or missing JSON string key | Empty string `""` or `False` |

## Rules
- Pure functions; malformed hex or Base64 input returns `""` without panicking.
