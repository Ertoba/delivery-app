# api/v1 Endpoint Reference — 6amMart (`mart`)

Every `api/v1` endpoint, called live, with the exact request that was sent and the response that came back.
Use it to see what an endpoint expects, which role can call it, and what its payload actually looks like.

Base URL: `{{host}}` — substitute your environment's host (the capture ran against a local instance).  
Scope: all `api/v1` endpoints — the core `routes/api/v1/api.php` plus the Rental, Service, AI, Reels and Tax module routes. **RideShare is excluded.**  
Captured: 2026-08-27 · 621 endpoints

## How to authenticate

| Role | Login endpoint | Body |
|---|---|---|
| Customer | `POST {{host}}/api/v1/auth/login` | `{"login_type":"manual","field_type":"email","email_or_phone":"…","password":"…"}` |
| Vendor | `POST {{host}}/api/v1/auth/vendor/login` | `{"email":"…","password":"…","vendor_type":"owner"}` |
| Delivery man | `POST {{host}}/api/v1/auth/delivery-man/login` | `{"phone":"…","password":"…"}` |
| Serviceman | `POST {{host}}/api/v1/service/serviceman/auth/login` | `{"phone":"…","password":"…"}` |

All of them return the token at `content.token`. Throughout this document that token is referenced as a variable:

| Variable | Holds the token from |
|---|---|
| `{{user_token}}` | customer login |
| `{{provider_token}}` | vendor login |
| `{{delivery_man_token}}` | delivery-man login |
| `{{serviceman_token}}` | serviceman login |

### Headers — read this before wiring anything up

| Header | Required on | Notes |
|---|---|---|
| `moduleId` | 218 endpoints | Numeric module id or slug. **403 `Module id required`** without it. |
| `zoneId` | zone-scoped customer endpoints | JSON array of zone ids, e.g. `[1]` — not a bare number. |
| `vendorType` | all 244 vendor endpoints | `owner` or `employee`. **403 `Vendor type required`** without it. |
| `Authorization: Bearer …` | customer and vendor endpoints | Standard bearer. |
| `X-localization` | optional, all | Locale code, e.g. `en`. |

> ⚠️ **Delivery-man and serviceman endpoints do not use the `Authorization` header.** Their token must be sent as a **`token` request field** — in the query string for GET, in the body otherwise. Sending it only as a bearer header returns `401 The selected token is invalid.`

> ⚠️ **Logging a vendor in again rotates that vendor's token** and invalidates the previous one. Don't hold two live sessions for the same vendor account.

### Module ids

`1` grocery · `2` pharmacy · `3` ecommerce · `4` food · `5` parcel · `6` rental · `16` service

Send the module id that matches the endpoint's domain — `6` for `/rental/*`, `16` for `/service/*`, otherwise the storefront module you're browsing.

## What the responses look like

Most endpoints wrap their payload in the standard envelope:

```json
{ "identical_code": "default_200", "message": "Successfully fetched", "content": { … }, "errors": [] }
```

Errors come back as `{"errors":[{"code":"<field>","message":"…"}]}`. Two things to code defensively around:

- **Status codes are not uniform.** Validation and business-rule failures arrive as `403`, `400`, `405` and `422`. Branch on the `errors` array, not on the status code alone.
- **A few Rental endpoints skip the envelope** and return a bare `{"message":"…"}`. Handle both shapes.

## Coverage

| Result | Count | What it means for you |
|---|---|---|
| Success (2xx) | 388 | Live sample payload captured below. |
| Validation | 138 | Endpoint works; the probe didn't send every required field. The error body lists exactly what's missing. |
| Not found | 95 | The probe used a placeholder id the test account doesn't own. Not an endpoint fault. |
| Auth required | 0 | Account-deletion and logout endpoints, called last once their token had been consumed. |
| Currently broken | 0 | None — every endpoint responded. |

Status distribution: `200`×377 · `201`×11 · `400`×4 · `403`×45 · `404`×95 · `405`×1 · `422`×88

## Known issues

No endpoint in this set returns a server error — every one of them responded.

Things that change what you'll see:

- **27 endpoints take file uploads** (`image`, `identity_image`, `documents`, …) that this capture did not send, so their samples show a validation error rather than a success payload. Send those as `multipart/form-data`, not JSON.
- **AI-assisted endpoints** (`/ai/*`, vendor content generation) return `422` unless an OpenAI key is configured — `The AI service returned an unexpected response`.
- **OTP / SMS / Firebase endpoints fail on this environment** because no gateway is configured. The request shape is still accurate; only delivery fails.
- **`verify-token` / `reset-password` return `400 Invalid token`** because the capture had no real OTP to present. Their parameter lists are correct.
- **Some `403`s are business rules, not auth failures** — `You cannot place empty orders`, `Only parcel order can be returned`, `You need to have at least 10 Points to convert`. Read `errors[].message`.
- **A 2xx here does not prove an endpoint is free of N+1 / lazy-loading problems.** Laravel only arms that guard when a query returns more than one row, so a lightly-seeded endpoint can pass an HTTP call and still be doing lazy loads. The project's own sweep tests are the authority on that.

## Endpoints

Alphabetical by URI. Replace `{{host}}` with your API host and the token variable with the value from that role's login.

### GET `api/v1/about-us`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/about-us' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":"<p>sssssssss6amMart is a complete Multi-vendor Food, Grocery, eCommerce, Parcel, Pharmacy, or any kind of products delivery system developed with powerful admin panel will help you to control your business smartly.<\/p>\r\n\r\n<p>Praesent fermentum finibus lacus. Nulla tincidunt lectus sed purus facilisis hendrerit. Maecenas volutpat elementum orci, tincidunt euismod ante facilisis ac. Integer dignissim iaculis varius. Mauris iaculis elit vel posuere pellentesque. Praesent a mi sed neque ullamcorper dignissim sed ut nibh. Sed purus dui, sodales in varius in, accumsan at libero. Vestibulum posuere dui et orci tincidun …[truncated]
```

### GET `api/v1/addon-category/list`

- **Auth:** `public`
- **Parameters:** `module_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/addon-category/list?module_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/advertisement/list`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/advertisement/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### POST `api/v1/ai/generate-form-image`

- **Auth:** `vendor`
- **Parameters:** `image` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/ai/generate-form-image' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Image is required","content":null,"errors":{"image":["Image is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### GET `api/v1/ai/generate-other-data`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**), `description` (**required**), `module_type` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/ai/generate-other-data?name=Audit+Probe&description=Audit+probe+description&module_type=grocery' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The AI service returned an unexpected response. Please try again later.","content":null,"errors":[{"code":"ai_service","message":"The AI service returned an unexpected response. Please try again later."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/ai/generate-title-and-description`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**), `langCode` (**required**), `module_type` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/ai/generate-title-and-description?name=Audit+Probe&langCode=en&module_type=grocery' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The AI service returned an unexpected response. Please try again later.","content":null,"errors":[{"code":"ai_service","message":"The AI service returned an unexpected response. Please try again later."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/ai/generate-title-suggestions`

- **Auth:** `vendor`
- **Parameters:** `keywords` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/ai/generate-title-suggestions?keywords=test&name=Ferrero' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The AI service returned an unexpected response. Please try again later.","content":null,"errors":[{"code":"ai_service","message":"The AI service returned an unexpected response. Please try again later."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/ai/generate-variation-data`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**), `description` (**required**), `module_type` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/ai/generate-variation-data?name=Audit+Probe&description=Audit+probe+description&module_type=grocery' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The AI service returned an unexpected response. Please try again later.","content":null,"errors":[{"code":"ai_service","message":"The AI service returned an unexpected response. Please try again later."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/app-download-section`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/app-download-section' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"download_user_app_section_status":1,"download_user_app_title":"Complete Multipurpose eBusiness Solution Complete Multipurpo","download_user_app_links":{"playstore_url":"https:\/\/drive.usercontent.google.com\/download?id=1W9KRSN2qGAyrCZEn7WjdilkJy6TSWjI2&authuser=0","apple_store_url":"https:\/\/6ammart-dev.6amdev.xyz\/"}},"errors":[]}
```

### POST `api/v1/auth/delivery-man/firebase-verify-token`

- **Auth:** `public`
- **Parameters:** `sessionInfo` (**required**), `phoneNumber` (**required**), `code` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/delivery-man/firebase-verify-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"sessionInfo":"test","phoneNumber":"test","code":"bogo"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"403","message":"Method doesn't allow unregistered callers (callers without established identity). Please use API Key or other form of API consumer identity to call this API."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/delivery-man/forgot-password`

- **Auth:** `public`
- **Parameters:** `phone` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/delivery-man/forgot-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"phone":"+8801700000000"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Otp Successfully Sent To Your Mail","content":null,"errors":[]}
```

### POST `api/v1/auth/delivery-man/login`

- **Auth:** `public`
- **Parameters:** `phone` (**required**), `password` (**required**), `type` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/delivery-man/login' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"phone":"+8801700000000","password":"Str0ng@Pass1"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"token":"<REDACTED>","topic":"delivery_man_1_1","zone_topic":"zone_1_delivery_man_push"},"errors":[]}
```

### PUT `api/v1/auth/delivery-man/reset-password`

- **Auth:** `public`
- **Parameters:** `phone` (**required**), `reset_token` (**required**), `password` (**required**), `confirm_password` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/auth/delivery-man/reset-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"phone":"+8801700000000","reset_token":"test","password":"Str0ng@Pass1","confirm_password":"Str0ng@Pass1"}'
```
- **Status:** 400
- **Response:**
```json
{"identical_code":"bad_request_400","message":"Bad request","content":null,"errors":[{"code":"invalid","message":"Invalid token."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/delivery-man/store`

- **Auth:** `public`
- **Parameters:** `f_name` (**required**), `l_name` (optional), `identity_type` (**required**), `identity_number` (**required**), `email` (**required**), `phone` (**required**), `password` (**required**), `zone_id` (**required**), `vehicle_id` (conditional — `required_if:type,is_delivery`), `earning` (**required**), `type` (**required**), `referral_code` (optional), `image` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/delivery-man/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"f_name":"Audit","l_name":"Probe","identity_type":"passport","identity_number":"test","email":"audit067f1079@example.com","phone":"+880925947625","password":"Str0ng@Pass1","zone_id":1,"vehicle_id":1,"earning":"test","type":"is_delivery","referral_code":"test"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Deliveryman added successfully","content":null,"errors":[]}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### POST `api/v1/auth/delivery-man/verify-token`

- **Auth:** `public`
- **Parameters:** `phone` (**required**), `reset_token` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/delivery-man/verify-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"phone":"+8801700000000","reset_token":"test"}'
```
- **Status:** 400
- **Response:**
```json
{"identical_code":"bad_request_400","message":"Bad request","content":null,"errors":[{"code":"reset_token","message":"Invalid token."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/auth/firebase-reset-password`

- **Auth:** `public`
- **Parameters:** `sessionInfo` (**required**), `phoneNumber` (**required**), `code` (**required**), `is_reset_token` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/auth/firebase-reset-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"sessionInfo":"test","phoneNumber":"test","code":"bogo","is_reset_token":1}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"403","message":"Method doesn't allow unregistered callers (callers without established identity). Please use API Key or other form of API consumer identity to call this API."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/firebase-verify-token`

- **Auth:** `public`
- **Parameters:** `session_info` (**required**), `phone` (**required**), `otp` (**required**), `login_type` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/firebase-verify-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"session_info":"test","phone":"+8801700000000","otp":"test","login_type":"manual"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"firebase","message":"Method doesn't allow unregistered callers (callers without established identity). Please use API Key or other form of API consumer identity to call this API."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/forgot-password`

- **Auth:** `public`
- **Parameters:** `verification_method` (**required**), `phone` (conditional — `required_if:verification_method,phone`), `email` (conditional — `required_if:verification_method,email`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/forgot-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"verification_method":"phone","phone":"+8801700000000","email":"6amtech@gmail.com"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"otp","message":"Failed to send sms"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/guest/request`

- **Auth:** `public`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/guest/request' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Successfully created","content":{"guest_id":6778},"errors":[]}
```

### POST `api/v1/auth/login`

- **Auth:** `public`
- **Parameters:** `login_type` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/login' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"login_type":"manual","field_type":"email","email_or_phone":"6amtech@gmail.com","password":"Str0ng@Pass1"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"token":"<REDACTED>","is_phone_verified":1,"is_email_verified":1,"is_personal_info":1,"is_exist_user":null,"login_type":"manual","email":"6amtech@gmail.com"},"errors":[]}
```

### PUT `api/v1/auth/reset-password`

- **Auth:** `public`
- **Parameters:** `reset_token` (**required**), `password` (**required**), `verification_method` (**required**), `phone` (conditional — `required_if:verification_method,phone`), `email` (conditional — `required_if:verification_method,email`), `confirm_password` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/auth/reset-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"reset_token":"test","password":"Str0ng@Pass1","verification_method":"phone","phone":"+8801700000000","email":"6amtech@gmail.com","confirm_password":"Str0ng@Pass1"}'
```
- **Status:** 400
- **Response:**
```json
{"identical_code":"bad_request_400","message":"Bad request","content":null,"errors":[{"code":"invalid","message":"Invalid otp"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/sign-up`

- **Auth:** `public`
- **Parameters:** `name` (**required**), `email` (optional), `phone` (**required**), `password` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/sign-up' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"name":"Audit Probe","email":"audit5754d558@example.com","phone":"+880918959514","password":"Str0ng@Pass1"}'
```
- **Status:** 405
- **Response:**
```json
{"identical_code":"method_not_allowed_405","message":"Method not allowed","content":null,"errors":[{"code":"otp","message":"Failed to send sms"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/update-info`

- **Auth:** `public`
- **Parameters:** `name` (**required**), `login_type` (**required**), `phone` (**required**), `email` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/update-info' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"name":"Audit Probe","login_type":"otp","phone":"+8801700000000","email":"6amtech@gmail.com"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The email has already been taken.","content":null,"errors":{"email":["The email has already been taken."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/vendor/forgot-password`

- **Auth:** `public`
- **Parameters:** `email` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/vendor/forgot-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"email":"6amtech@gmail.com"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"not-found","message":"Email not found!"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/auth/vendor/login`

- **Auth:** `public`
- **Parameters:** `email` (**required**), `password` (**required**), `vendor_type` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/vendor/login' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"email":"grocery.store2@demo.com","password":"Str0ng@Pass1","vendor_type":"owner"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"token":"<REDACTED>","zone_wise_topic":"zone_1_store","module_type":"grocery"},"errors":[]}
```

### POST `api/v1/auth/vendor/register`

- **Auth:** `public`
- **Parameters:** `f_name` (**required**), `l_name` (optional), `latitude` (**required**), `longitude` (**required**), `email` (**required**), `phone` (**required**), `minimum_delivery_time` (**required**), `maximum_delivery_time` (**required**), `delivery_time_type` (**required**), `password` (**required**), `zone_id` (**required**), `module_id` (**required**), `translations` (**required**), `translations.*.locale` (**required**), `translations.*.key` (**required**), `translations.*.value` (**required**), `logo` (optional), `cover_photo` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/vendor/register' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"f_name":"Audit","l_name":"Probe","latitude":"23.735129","longitude":"90.425614","email":"audite46a2b3b@example.com","phone":"+880970086826","minimum_delivery_time":"09:00","maximum_delivery_time":"09:00","delivery_time_type":"09:00","password":"Str0ng@Pass1","zone_id":1,"module_id":1,"translations":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Name and description in english is required","content":null,"errors":{"translations":["Name and description in english is required"],"logo":["Image is required"]}}
```
- *Takes file upload(s) not exercised here: `logo`, `cover_photo` — send as `multipart/form-data`.*

### PUT `api/v1/auth/vendor/reset-password`

- **Auth:** `public`
- **Parameters:** `email` (**required**), `reset_token` (**required**), `password` (**required**), `confirm_password` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/auth/vendor/reset-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"email":"6amtech@gmail.com","reset_token":"test","password":"Str0ng@Pass1","confirm_password":"Str0ng@Pass1"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The selected email is invalid.","content":null,"errors":{"email":["The selected email is invalid."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/vendor/verify-token`

- **Auth:** `public`
- **Parameters:** `email` (**required**), `reset_token` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/vendor/verify-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"email":"6amtech@gmail.com","reset_token":"test"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The selected email is invalid.","content":null,"errors":{"email":["The selected email is invalid."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/auth/verify-phone`

- **Auth:** `public`
- **Parameters:** `otp` (**required**), `verification_type` (**required**), `phone` (conditional — `required_if:verification_type,phone`), `email` (conditional — `required_if:verification_type,email`), `login_type` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/verify-phone' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"otp":"test","verification_type":"phone","phone":"+8801700000000","email":"6amtech@gmail.com","login_type":"manual"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"message":"Phone number is already verified"},"errors":[]}
```

### POST `api/v1/auth/verify-token`

- **Auth:** `public`
- **Parameters:** `reset_token` (**required**), `verification_method` (**required**), `phone` (conditional — `required_if:verification_method,phone`), `email` (conditional — `required_if:verification_method,email`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/auth/verify-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"reset_token":"test","verification_method":"phone","phone":"+8801700000000","email":"6amtech@gmail.com"}'
```
- **Status:** 400
- **Response:**
```json
{"identical_code":"bad_request_400","message":"Bad request","content":null,"errors":[{"code":"invalid","message":"Invalid OTP."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/banners`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/banners' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"campaigns":[{"id":17,"title":"Illo minima id quaer","image":"2026-06-22-6a38cdaf218e4.webp","description":"Amet libero tempore","status":1,"admin_id":null,"created_at":"2025-12-28T10:04:33.000000Z","updated_at":"2026-06-22T11:52:47.000000Z","start_time":"08:55","end_time":"18:40","module_id":1,"slug":null,"available_date_starts":"2026-06-22","available_date_ends":"2027-07-15","image_full_url":"{{host}}\/storage\/app\/public\/campaign\/2026-06-22-6a38cdaf218e4.webp","storage":[{"data_id":17,"data_type":"App\\Models\\Campaign","key":"image","value":"public"}],"translations":[{"id":3537,"translationable_type":"App\\Mod …[truncated]
```

### GET `api/v1/banners/{store_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/banners/3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/brand`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/brand' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":2,"name":"Stationary Point","slug":"nutri-science","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2024-10-29-6720909aec3c0.png","items_count":1},{"id":3,"name":"Grocerylia","slug":"razer","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2024-10-29-672090fcad137.png","items_count":1},{"id":4,"name":"New Market","slug":"johnsons-johnsons","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2024-10-29-672090e50c6dd.png","items_count":0},{"id":5,"name":"Shop Center","slug":"canon","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2024-10-29-672090ad5a562.png","items_count":0},{ …[truncated]
```

### GET `api/v1/brand/items/{brand_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/brand/items/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":29,"name":"Olive Oil Butter","slug":"olive-oil-butter29","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-10-27-671e045a548e1.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671e045a52c6a.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e045a53602.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e045a53c98.png"],"price":38,"discount":20,"discount_type":"amount","store_discount":0,"flash_sale":1,"stock":19,"unit_type":"Kg","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":3,"rating_count":1,"available_time_starts …[truncated]
```

### GET `api/v1/campaigns/basic`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/campaigns/basic' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":17,"title":"Illo minima id quaer","description":"Amet libero tempore","image_full_url":"{{host}}\/storage\/app\/public\/campaign\/2026-06-22-6a38cdaf218e4.webp","available_date_starts":"2026-06-22","available_date_ends":"2027-07-15","start_time":"08:55","end_time":"18:40"},{"id":20,"title":"Offer Offer Offer Offer Offer Offer","description":"Offer Offer Offer Offer Offer Offer","image_full_url":"{{host}}\/storage\/app\/public\/campaign\/2026-06-22-6a38cdce2e51c.webp","available_date_starts":"2026-06-22","available_date_ends":"2027-10-02","start_time":"09:02","end_time":"22:02"}],"pagination":{"current_p …[truncated]
```

### GET `api/v1/campaigns/basic-campaign-details`

- **Auth:** `public`
- **Parameters:** `basic_campaign_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/campaigns/basic-campaign-details?basic_campaign_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/campaigns/item`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/campaigns/item' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":29,"title":"test organic shop","description":"tres","slug":"test-organic-shop","image_full_url":"{{host}}\/storage\/app\/public\/campaign\/2026-06-28-6a4116bac64b2.webp","price":100,"discount":10,"discount_type":"percent","store_discount":0,"stock":5,"unit_type":"Kg","maximum_cart_quantity":12,"veg":0,"available_date_starts":"2026-06-28","available_date_ends":"2028-12-30","available_time_starts":"00:03","available_time_ends":"21:34","category_id":63,"category_ids":[{"id":"1","position":1},{"id":"63","position":2}],"module_id":1,"module_type":"grocery","store_id":1,"store_name":"Organic Shop","store_slug …[truncated]
```

### GET `api/v1/cancelation`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/cancelation' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":"<h1>This is a demo cancelation policy<\/h1>\r\n\r\n<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed iaculis nunc tortor, non malesuada nunc tincidunt id. Sed porta ex nec sapien convallis hendrerit. Pellentesque auctor dapibus eleifend. Cras tempus, sapien sed dignissim consequat, dolor nunc volutpat urna, at hendrerit dui dolor dapibus odio. Sed dolor purus, luctus in dui non, fermentum imperdiet nibh. Aenean at libero ut libero auctor finibus. Vivamus eu nulla vel risus dapibus tincidunt eget non orci. Sed lorem velit, sollicitudin eu mi vitae, rutrum congue orci. Phasellus sit amet ex accumsan, semp …[truncated]
```

### GET `api/v1/cashback/getCashback`

- **Auth:** `customer`
- **Parameters:** `amount` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/cashback/getCashback?amount=100' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":13,"calculated_amount":10,"cashback_amount":10,"cashback_type":"percentage","min_purchase":10,"max_discount":100},"errors":[]}
```

### GET `api/v1/cashback/list`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/cashback/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"title":"Get Instant $10 Cashback When You Book a Full Day Rental!","cashback_type":"amount","cashback_amount":10,"min_purchase":100,"max_discount":0,"end_date":"2029-07-27"},{"title":"D=M","cashback_type":"percentage","cashback_amount":10,"min_purchase":10,"max_discount":100,"end_date":"2032-10-21"},{"title":"get 20% discount","cashback_type":"percentage","cashback_amount":10,"min_purchase":12,"max_discount":0,"end_date":"2032-07-13"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":3,"from":1,"to":3}},"errors":[]}
```

### GET `api/v1/categories`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":2,"name":"Personal Care","slug":"seafood2","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c71a0338d.png","module_id":1,"featured":0,"childes":[{"id":133,"name":"Shampoo","slug":"shampoo"},{"id":134,"name":"Soap","slug":"soap"},{"id":135,"name":"Skincare","slug":"skincare"},{"id":136,"name":"Oral Care","slug":"oral-care"}]},{"id":4,"name":"Snacks","slug":"snacks4","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-23-6718f254cb596.png","module_id":1,"featured":0,"childes":[{"id":125,"name":"Chips","slug":"chips"},{"id":126,"name":"Chocolates","slug":"chocolate …[truncated]
```

### GET `api/v1/categories/childes/{category_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories/childes/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":133,"name":"Shampoo","slug":"shampoo","image_full_url":null,"module_id":1,"featured":0,"childes":[]},{"id":134,"name":"Soap","slug":"soap","image_full_url":null,"module_id":1,"featured":0,"childes":[]},{"id":135,"name":"Skincare","slug":"skincare","image_full_url":null,"module_id":1,"featured":0,"childes":[]},{"id":136,"name":"Oral Care","slug":"oral-care","image_full_url":null,"module_id":1,"featured":0,"childes":[]}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":4,"from":1,"to":4}},"errors":[]}
```

### GET `api/v1/categories/featured/items`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories/featured/items' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":451,"name":"a","slug":"a-4","image_full_url":null,"images_full_url":[null,null],"price":11,"discount":1,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":0,"unit_type":"Kg","maximum_cart_quantity":1,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":null,"available_time_ends":null,"brand_name":null,"category_ids":[{"id":"9","position":1},{"id":"47","position":2}],"module_id":1,"module_type":"grocery","store_id":12,"store_name":"Sk General Store","store_slug":"sk-general-store12","store_image_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10 …[truncated]
```

### GET `api/v1/categories/items/list`

- **Auth:** `public`
- **Parameters:** `category_ids` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories/items/list?category_ids%5B0%5D=2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":115,"name":"Praise Daily Style Mayonnaise","slug":"praise-daily-style-mayonnaise115","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b964484.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b963233.png"],"price":230,"discount":30,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1996,"unit_type":"Ltr","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"2","position":1},{"id":" …[truncated]
```

### GET `api/v1/categories/items/{category_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories/items/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":115,"name":"Praise Daily Style Mayonnaise","slug":"praise-daily-style-mayonnaise115","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b964484.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b963233.png"],"price":230,"discount":30,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1996,"unit_type":"Ltr","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"2","position":1},{"id":" …[truncated]
```

### GET `api/v1/categories/items/{category_id}/all`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories/items/2/all' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[{"id":115,"name":"Praise Daily Style Mayonnaise","slug":"praise-daily-style-mayonnaise115","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b964484.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b963233.png"],"price":230,"discount":30,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1996,"unit_type":"Ltr","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"2","position":1},{"id":"134","po …[truncated]
```

### GET `api/v1/categories/popular`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories/popular' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":5,"name":"Pantry","slug":"pantry5","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-23-6718f227a2627.png","module_id":1,"featured":0,"childes":[]},{"id":6,"name":"Frozen","slug":"frozen6","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-11-17-6739638489261.png","module_id":1,"featured":0,"childes":[]},{"id":7,"name":"Beverages","slug":"beverages7","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-23-6718f14c85661.png","module_id":1,"featured":1,"childes":[]},{"id":8,"name":"Bakery","slug":"bakery8","image_full_url":null,"module_id":1,"featured":1,"chi …[truncated]
```

### GET `api/v1/categories/stores/list`

- **Auth:** `public`
- **Parameters:** `category_ids` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories/stores/list?category_ids%5B0%5D=2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":3,"name":"Eorange","slug":"eorange3","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27-671e34990da6e.png","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2024-10-24-671a30c1c05a1.png","address":"House: 00, Road: 00, City-000, Country","latitude":"23.805438526268976","longitude":"90.36799765290114","zone_id":1,"module_id":1,"delivery":true,"take_away":true,"free_delivery":false,"schedule_order":true,"delivery_time":"1-1 min","minimum_order":1,"minimum_shipping_charge":0,"maximum_shipping_charge":0,"per_km_shipping_charge":0,"veg":1,"non_veg":1,"active":false,"open": …[truncated]
```

### GET `api/v1/categories/stores/{category_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories/stores/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":3,"name":"Eorange","slug":"eorange3","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27-671e34990da6e.png","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2024-10-24-671a30c1c05a1.png","address":"House: 00, Road: 00, City-000, Country","latitude":"23.805438526268976","longitude":"90.36799765290114","zone_id":1,"module_id":1,"delivery":true,"take_away":true,"free_delivery":false,"schedule_order":true,"delivery_time":"1-1 min","minimum_order":1,"minimum_shipping_charge":0,"maximum_shipping_charge":0,"per_km_shipping_charge":0,"veg":1,"non_veg":1,"active":false,"open": …[truncated]
```

### GET `api/v1/categories/top`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/categories/top' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":11,"name":"Dairy & Eggs","slug":"dairy-eggs11","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-23-6718f111d1be2.png","module_id":1,"featured":0,"childes":[{"id":106,"name":"Milk","slug":"milk"},{"id":107,"name":"Cheese","slug":"cheese"},{"id":108,"name":"Eggs","slug":"yogurt"},{"id":109,"name":"Butter","slug":"butter"}],"order_count":21},{"id":10,"name":"Meat","slug":"meat10","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-23-6718f120700a2.png","module_id":1,"featured":0,"childes":[{"id":59,"name":"Processed Meat","slug":"processed-meat59"},{"id":60,"name":"Lamb", …[truncated]
```

### GET `api/v1/common-condition`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/common-condition' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":2,"name":"Oral Care"},{"id":3,"name":"Eye & Ear"},{"id":4,"name":"Digestive Health"},{"id":8,"name":"Skin & Hair Condition"},{"id":12,"name":"Baby Care"},{"id":13,"name":"Devices"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":6,"from":1,"to":6}},"errors":[]}
```

### GET `api/v1/common-condition/items/{condition_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/common-condition/items/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":79,"name":"Electric Toothbrush","slug":"electric-toothbrush79","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-11-06-672ae6f52573f.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-11-06-672ae6f5225be.png","{{host}}\/storage\/app\/public\/product\/2024-11-06-672ae6f523bce.png"],"price":25,"discount":0,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":996,"unit_type":"Pcs","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null, …[truncated]
```

### GET `api/v1/common-condition/list`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/common-condition/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":2,"name":"Oral Care"},{"id":3,"name":"Eye & Ear"},{"id":4,"name":"Digestive Health"},{"id":5,"name":"Allergy & Asthma"},{"id":6,"name":"Blood Pressure & Heart Disease"},{"id":7,"name":"Blood Pressure"},{"id":8,"name":"Skin & Hair Condition"},{"id":10,"name":"Infection"},{"id":11,"name":"All Medicine"},{"id":12,"name":"Baby Care"},{"id":13,"name":"Devices"},{"id":14,"name":"Dhaka"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":12,"from":1,"to":12}},"errors":[]}
```

### GET `api/v1/config`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/config' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"business_name":"6amMartt","logo_full_url":"{{host}}\/storage\/app\/public\/business\/2026-06-09-6a279a7d033de.webp","address":"176 New Market - Pilkhana Rd, Dhaka 1205, Bangladesh","phone":"+8801700000000","email":"support@6amtech.com","country":"BD","default_location":{"lat":"23.73219380283711","lng":"90.37973642349243"},"currency_symbol":"\u09f3","currency_symbol_direction":"right","app_minimum_version_android":0,"app_url_android":"https:\/\/drive.usercontent.google.com\/download?id=1W9KRSN2qGAyrCZEn7WjdilkJy6TSWjI2&authuser=0","app_url_ios":"https:\/\/6ammart-dev.6amdev.xyz\/","app_minimum_version_android_store": …[truncated]
```

### GET `api/v1/config/direction-api`

- **Auth:** `public`
- **Parameters:** `origin_lat` (**required**), `origin_lng` (**required**), `destination_lat` (**required**), `destination_lng` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/config/direction-api?origin_lat=test&origin_lng=test&destination_lat=test&destination_lng=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The origin lat must be a number.","content":null,"errors":{"origin_lat":["The origin lat must be a number."],"origin_lng":["The origin lng must be a number."],"destination_lat":["The destination lat must be a number."],"destination_lng":["The destination lng must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/config/distance-api`

- **Auth:** `public`
- **Parameters:** `origin_lat` (**required**), `origin_lng` (**required**), `destination_lat` (**required**), `destination_lng` (**required**), `mode` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/config/distance-api?origin_lat=test&origin_lng=test&destination_lat=test&destination_lng=test&mode=DRIVE' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The origin lat must be a number.","content":null,"errors":{"origin_lat":["The origin lat must be a number."],"origin_lng":["The origin lng must be a number."],"destination_lat":["The destination lat must be a number."],"destination_lng":["The destination lng must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/config/geocode-api`

- **Auth:** `public`
- **Parameters:** `lat` (**required**), `lng` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/config/geocode-api?lat=23.735129&lng=90.425614' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"error_message":"The provided API key is invalid. ","results":[],"status":"REQUEST_DENIED"},"errors":[]}
```

### GET `api/v1/config/get-analytic-scripts`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/config/get-analytic-scripts' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"type":"google_analytics","script_id":"14323242345"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### GET `api/v1/config/get-zone-id`

- **Auth:** `public`
- **Parameters:** `lat` (**required**), `lng` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/config/get-zone-id?lat=23.735129&lng=90.425614' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"zone_id":"[3,1]","zone_data":[{"id":3,"status":1,"cash_on_delivery":true,"digital_payment":true,"offline_payment":true,"increased_delivery_fee_status":0,"increase_delivery_charge_message":null,"modules":[{"id":1,"module_name":"Grocery","module_type":"grocery","stores_count":15,"theme_id":1,"additional_delivery_option_status":false,"delivery_options":[],"pivot":{"zone_id":3,"per_km_shipping_charge":5,"minimum_shipping_charge":50,"maximum_shipping_charge":200,"maximum_cod_order_amount":null,"delivery_charge_type":"fixed","fixed_shipping_charge":100,"minimum_delivery_charge":null}},{"id":5,"module_name":"Parcel","modul …[truncated]
```

### GET `api/v1/config/place-api-autocomplete`

- **Auth:** `public`
- **Parameters:** `search_text` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/config/place-api-autocomplete?search_text=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"error":{"code":400,"message":"API key not valid. Please pass a valid API key.","status":"INVALID_ARGUMENT","details":[{"@type":"type.googleapis.com\/google.rpc.ErrorInfo","reason":"API_KEY_INVALID","domain":"googleapis.com","metadata":{"service":"places.googleapis.com"}},{"@type":"type.googleapis.com\/google.rpc.LocalizedMessage","locale":"en-US","message":"API key not valid. Please pass a valid API key."}]}},"errors":[]}
```

### GET `api/v1/config/place-api-details`

- **Auth:** `public`
- **Parameters:** `placeid` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/config/place-api-details?placeid=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"error":{"code":400,"message":"API key not valid. Please pass a valid API key.","status":"INVALID_ARGUMENT","details":[{"@type":"type.googleapis.com\/google.rpc.ErrorInfo","reason":"API_KEY_INVALID","domain":"googleapis.com","metadata":{"service":"places.googleapis.com"}},{"@type":"type.googleapis.com\/google.rpc.LocalizedMessage","locale":"en-US","message":"API key not valid. Please pass a valid API key."}]}},"errors":[]}
```

### GET `api/v1/coupon/apply`

- **Auth:** `customer`
- **Parameters:** `code` (**required**), `store_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/coupon/apply?code=bogo&store_id=3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"coupon","message":"Coupon not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/coupon/list`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/coupon/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"title":"Vggv","code":"cttg","start_date":"2026-04-28","expire_date":"2029-12-30","min_purchase":5,"max_discount":1000,"discount":100,"discount_type":"percent","coupon_type":"default","data":"\"\"","store_id":1,"store":{"id":1,"name":"Organic Shop","verified_seller":1}},{"title":"yuty","code":"u477","start_date":"2026-03-08","expire_date":"2026-08-29","min_purchase":50,"max_discount":0,"discount":60,"discount_type":"amount","coupon_type":"default","data":"\"\"","store_id":11,"store":{"id":11,"name":"Online market","verified_seller":1}},{"title":"53464","code":"7u4i746","start_date":"2026-03-08","expire_date" …[truncated]
```

### GET `api/v1/coupon/list/all`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/coupon/list/all' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"title":"Vggv","code":"cttg","start_date":"2026-04-28","expire_date":"2029-12-30","min_purchase":5,"max_discount":1000,"discount":100,"discount_type":"percent","coupon_type":"default","data":"\"\"","store_id":1,"store":{"id":1,"name":"Organic Shop","verified_seller":1}},{"title":"yuty","code":"u477","start_date":"2026-03-08","expire_date":"2026-08-29","min_purchase":50,"max_discount":0,"discount":60,"discount_type":"amount","coupon_type":"default","data":"\"\"","store_id":11,"store":{"id":11,"name":"Online market","verified_seller":1}},{"title":"53464","code":"7u4i746","start_date":"2026-03-08","expire_date" …[truncated]
```

### POST `api/v1/customer/address/add`

- **Auth:** `customer`
- **Parameters:** `contact_person_name` (**required**), `address_type` (**required**), `contact_person_number` (**required**), `address` (**required**), `longitude` (**required**), `latitude` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/address/add' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"contact_person_name":"test","address_type":"test","contact_person_number":"+8801700000000","address":"test","longitude":"90.425614","latitude":"23.735129"}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Successfully created","content":{"zone_ids":[1,3,14,16]},"errors":[]}
```

### DELETE `api/v1/customer/address/delete`

- **Auth:** `customer`
- **Parameters:** `address_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/customer/address/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"address_id":200}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":null,"errors":[]}
```

### GET `api/v1/customer/address/list`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/address/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":205,"address_type":"test","address":"test","contact_person_name":"test","contact_person_number":"+8801700000000","latitude":"23.735129","longitude":"90.425614","road":null,"house":null,"floor":null,"zone_id":1,"zone_ids":[16,14,3,1]},{"id":204,"address_type":"test","address":"test","contact_person_name":"test","contact_person_number":"+8801700000000","latitude":"23.735129","longitude":"90.425614","road":null,"house":null,"floor":null,"zone_id":1,"zone_ids":[16,14,3,1]},{"id":203,"address_type":"test","address":"test","contact_person_name":"test","contact_person_number":"+8801700000000","latitude":"23.73 …[truncated]
```

### PUT `api/v1/customer/address/update/{id}`

- **Auth:** `customer`
- **Parameters:** `contact_person_name` (**required**), `address_type` (**required**), `contact_person_number` (**required**), `address` (**required**), `longitude` (**required**), `latitude` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/customer/address/update/200' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"contact_person_name":"test","address_type":"test","contact_person_number":"+8801700000000","address":"test","longitude":"90.425614","latitude":"23.735129"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":{"zone_id":1},"errors":[]}
```

### GET `api/v1/customer/ai-chat/conversations`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/ai-chat/conversations' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"identity","message":"Provide either authentication token or guest_id."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/customer/ai-chat/conversations/{id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/customer/ai-chat/conversations/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"identity","message":"Provide either authentication token or guest_id."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/customer/ai-chat/messages`

- **Auth:** `public`
- **Parameters:** `conversation_id` (**required**), `limit` (optional), `offset` (optional), `guest_id` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/ai-chat/messages?conversation_id=1&limit=10&offset=1&guest_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"not_found","message":"Conversation not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/customer/ai-chat/send`

- **Auth:** `public`
- **Parameters:** `message` (**required**), `conversation_id` (optional), `guest_id` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/ai-chat/send' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"message":"audit probe","conversation_id":1,"guest_id":"1"}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Successfully created","content":{"id":756,"conversation_id":116,"role":"assistant","content":"I'm sorry, I couldn't process that right now. Please try again.","tool_name":null,"metadata":{"products":[],"stores":[],"categories":[],"cart_items":[],"cart_updated":false,"cart":{"stores":[],"grand_total":0,"total_items":0}},"created_at":"2026-08-27T08:13:02.000000Z"},"errors":[]}
```

### GET `api/v1/customer/automated-message`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/automated-message' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":2,"message":"Need to change the phone number for delivery."},{"id":1,"message":"Delivery address need to change"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":2,"from":1,"to":2}},"errors":[]}
```

### POST `api/v1/customer/cart/add`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `item_id` (**required**), `model` (**required**), `price` (**required**), `quantity` (**required**), `reel_id` (optional), `store_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/cart/add' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","item_id":101,"model":"Item","price":100,"quantity":1,"reel_id":2,"store_id":3}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Successfully created","content":{"data":[{"id":7068,"module_id":1,"store_id":3,"price":100,"quantity":1,"variation":[],"add_on_ids":[],"add_on_qtys":[],"item":{"id":101,"name":"Ferrero Rocher Chocolate Box","slug":null,"image_full_url":null,"images_full_url":[null],"price":390,"discount":45,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1879,"unit_type":"Pack","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":4,"rating_count":2,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null,"category_ids":[{"id":"11","position":1}],"module_id":1,"module_type":"grocery","store_ …[truncated]
```

### POST `api/v1/customer/cart/add-multiple`

- **Auth:** `customer_or_guest`
- **Parameters:** `item_list` (**required**), `store_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/cart/add-multiple' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"item_list":[],"store_id":3}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The item list field is required.","content":null,"errors":{"item_list":["The item list field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/customer/cart/get-all`

- **Auth:** `customer_or_guest`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/cart/get-all' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[{"store":{"id":3,"name":"Eorange","slug":"eorange3","module_type":"grocery","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27-671e34990da6e.png","item_count":1,"delivery_time":"1-1 min","min_delivery_time":1,"max_delivery_time":1,"distance":9772.325650085459,"distance_km":9.77},"carts":[{"id":7068,"module_id":1,"store_id":3,"price":100,"quantity":1,"variation":[],"add_on_ids":[],"add_on_qtys":[],"item":{"id":101,"name":"Ferrero Rocher Chocolate Box","slug":null,"image_full_url":null,"images_full_url":[null],"price":390,"discount":45,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock": …[truncated]
```

### GET `api/v1/customer/cart/list`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `store_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/cart/list?guest_id=1&store_id=3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":7068,"module_id":1,"store_id":3,"price":100,"quantity":1,"variation":[],"add_on_ids":[],"add_on_qtys":[],"item":{"id":101,"name":"Ferrero Rocher Chocolate Box","slug":null,"image_full_url":null,"images_full_url":[null],"price":390,"discount":45,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1879,"unit_type":"Pack","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":4,"rating_count":2,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null,"category_ids":[{"id":"11","position":1}],"module_id":1,"module_type":"grocery","store_id":3, …[truncated]
```

### DELETE `api/v1/customer/cart/remove`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/customer/cart/remove' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### DELETE `api/v1/customer/cart/remove-item`

- **Auth:** `customer_or_guest`
- **Parameters:** `cart_id` (**required**), `guest_id` (**required**), `store_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/customer/cart/remove-item' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"cart_id":7067,"guest_id":"1","store_id":3}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"cart","message":"Cart not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/customer/cart/update`

- **Auth:** `customer_or_guest`
- **Parameters:** `cart_id` (**required**), `guest_id` (**required**), `price` (**required**), `quantity` (**required**), `store_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/cart/update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"cart_id":7067,"guest_id":"1","price":100,"quantity":1,"store_id":3}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":{"data":[{"id":7068,"module_id":1,"store_id":3,"price":100,"quantity":1,"variation":[],"add_on_ids":[],"add_on_qtys":[],"item":{"id":101,"name":"Ferrero Rocher Chocolate Box","slug":null,"image_full_url":null,"images_full_url":[null],"price":390,"discount":45,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1879,"unit_type":"Pack","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":4,"rating_count":2,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null,"category_ids":[{"id":"11","position":1}],"module_id":1,"module_type":"grocery","store …[truncated]
```

### PUT `api/v1/customer/cm-firebase-token`

- **Auth:** `customer`
- **Parameters:** `cm_firebase_token` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/customer/cm-firebase-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"cm_firebase_token":"test"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":null,"errors":[]}
```

### GET `api/v1/customer/info`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/info' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":8,"f_name":"6am","l_name":"Tech","phone":"+8801700000000","email":"6amtech@gmail.com","image":"2026-07-02-6a45fd3b80ee9.webp","image_full_url":"{{host}}\/storage\/app\/public\/profile\/2026-07-02-6a45fd3b80ee9.webp","storage":[{"id":894,"data_type":"App\\Models\\User","data_id":8,"key":"image","value":"public","created_at":"2026-07-02 17:55:07","updated_at":"2026-07-02 17:55:07"}],"is_phone_verified":1,"is_email_verified":0,"email_verified_at":null,"created_at":"2022-03-23T16:53:45.000000Z","updated_at":"2026-08-27T08:13:03.000000Z","status":1,"pro_status":false,"login_medium":"manual","zone_id":null,"wallet_bal …[truncated]
```

### POST `api/v1/customer/loyalty-point/point-transfer`

- **Auth:** `customer`
- **Parameters:** `point` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/loyalty-point/point-transfer' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"point":10}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"point","message":"Insufficient point"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/customer/loyalty-point/transactions`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/loyalty-point/transactions' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"credit":6,"debit":0,"transaction_type":"order_place","reference":"102957","created_at":"2026-07-15 00:21:59"},{"credit":2,"debit":0,"transaction_type":"order_place","reference":"102956","created_at":"2026-07-15 00:09:14"},{"credit":8,"debit":0,"transaction_type":"order_place","reference":"102955","created_at":"2026-07-15 00:02:55"},{"credit":10,"debit":0,"transaction_type":"order_place","reference":"102952","created_at":"2026-07-14 23:56:24"},{"credit":14,"debit":0,"transaction_type":"order_place","reference":"102953","created_at":"2026-07-14 23:05:17"},{"credit":9,"debit":0,"transaction_type":"order_place" …[truncated]
```

### GET `api/v1/customer/message/details`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/message/details' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"status":false,"conversation":null,"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/customer/message/list`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/message/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"type":null,"data":[{"id":73,"sender_type":"vendor","receiver_type":"customer","unread_message_count":1,"last_message_time":"2026-08-20 13:40:09","sender":{"id":52,"f_name":"CityRide Rentals","l_name":"","phone":"+1 959-252-4064","image_full_url":"{{host}}\/storage\/app\/public\/store\/2025-02-05-67a33b277371b.png"},"receiver":{"id":16,"f_name":"Audit","l_name":"Probe","phone":"+8801700000000","image_full_url":"{{host}}\/storage\/app\/public\/profile\/2026-07-02-6a45fd3b80ee9.webp"},"last_message":{"sender_id":52,"message":"audit probe","file_full_url":[],"is_seen":0,"created_at":"2026-08-20T07:40:09.000000Z"}},{"id" …[truncated]
```

### GET `api/v1/customer/message/search-list`

- **Auth:** `customer`
- **Parameters:** `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/message/search-list?name=Ferrero' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### POST `api/v1/customer/message/send`

- **Auth:** `customer`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/message/send' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Validation failed","content":null,"errors":[{"code":"receiver_id","message":"Invalid receiver"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/customer/monthly-order/details`

- **Auth:** `customer`
- **Parameters:** `id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/monthly-order/details?id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/customer/monthly-order/list`

- **Auth:** `customer`
- **Parameters:** `module_type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/monthly-order/list?module_type=grocery' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":5,"order_id":102674,"module_id":1,"module_type":"grocery","remind_at":"2026-04-18","status":"sent","store":{"id":14,"name":"Smart Shopping","logo":null},"items_count":1,"items_preview":[{"id":382,"item_type":"item","name":"Dgd","image":null,"price":500,"old_price":6000,"quantity":1,"is_available":true}]},{"id":11,"order_id":102797,"module_id":1,"module_type":"grocery","remind_at":"2026-07-26","status":"sent","store":{"id":11,"name":"Online market","logo":null},"items_count":4,"items_preview":[{"id":15,"item_type":"item","name":"Barilla Protein Pasta","image":"{{host}}\/storage\/app\/public\/product\/202 …[truncated]
```

### DELETE `api/v1/customer/monthly-order/remove`

- **Auth:** `customer`
- **Parameters:** `id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/customer/monthly-order/remove' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/customer/monthly-order/reorder`

- **Auth:** `customer`
- **Parameters:** `reminder_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/monthly-order/reorder' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"reminder_id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/customer/notifications`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/notifications' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":10499,"created_at":"2026-08-12 16:41:46","updated_at":"2026-08-12T10:41:46.000000Z","image_full_url":null,"data":{"title":"Order Notification","description":"Customer Ones, Your order is Processing by Miracle","order_id":103013,"image":"","type":"order_status"}},{"id":10500,"created_at":"2026-08-12 16:41:49","updated_at":"2026-08-12T10:41:49.000000Z","image_full_url":null,"data":{"title":"Order Notification","description":"Delivery man is on the way. For this order 103013","order_id":103013,"image":"","type":"order_status"}},{"id":10501,"created_at":"2026-08-12 16:43:09","updated_at":"2026-08-12T10:43:0 …[truncated]
```

### POST `api/v1/customer/order-again/reorder`

- **Auth:** `customer`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/order-again/reorder' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"order_id":100024}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"cart_count":1,"added_count":1,"skipped_count":0,"unavailable_items":[],"skipped_items":[]},"errors":[]}
```

### GET `api/v1/customer/order/all-running-orders`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/all-running-orders?guest_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":103008,"order_type":"order","status":"pending","is_repeat":0,"created_at":"2026-08-04 21:21:29"},{"id":103007,"order_type":"order","status":"pending","is_repeat":0,"created_at":"2026-08-04 19:16:12"},{"id":102999,"order_type":"order","status":"pending","is_repeat":0,"created_at":"2026-07-29 17:52:43"},{"id":102996,"order_type":"order","status":"pending","is_repeat":0,"created_at":"2026-07-29 17:20:00"},{"id":102992,"order_type":"order","status":"pending","is_repeat":0,"created_at":"2026-07-29 00:40:13"},{"id":102989,"order_type":"order","status":"pending","is_repeat":0,"created_at":"2026-07-28 23:46:41" …[truncated]
```

### PUT `api/v1/customer/order/cancel`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `order_id` (**required**), `reason` (conditional — `required_without:note`)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/customer/order/cancel' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","order_id":100024,"reason":"audit probe"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":null,"errors":[]}
```

### GET `api/v1/customer/order/cancellation-reasons`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/cancellation-reasons' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":3,"reason":"Fake customer"},{"id":4,"reason":"Product shortage"},{"id":6,"reason":"For bad weather, can't serve order"},{"id":7,"reason":"Right now, I am busy to serve another order"},{"id":8,"reason":"I ordered the wrong food"},{"id":9,"reason":"Boken"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":6,"from":1,"to":6}},"errors":[]}
```

### DELETE `api/v1/customer/order/delete`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `order_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/customer/order/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","order_id":100024}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/customer/order/details`

- **Auth:** `customer_or_guest`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/details?order_id=100024' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/customer/order/get-Tax`

- **Auth:** `customer_or_guest`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/order/get-Tax' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"tax_amount":0,"tax_status":"included","tax_included":1},"errors":[]}
```

### POST `api/v1/customer/order/get-surge-price`

- **Auth:** `customer_or_guest`
- **Parameters:** `zone_id` (**required**), `module_id` (**required**), `date_time` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/order/get-surge-price' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"zone_id":1,"module_id":1,"date_time":"2026-08-27"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"title":"","customer_note":"","customer_note_status":0,"price":0,"price_type":"amount"},"errors":[]}
```

### GET `api/v1/customer/order/last`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/last' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/customer/order/list`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/list?guest_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":102957,"user_id":8,"order_amount":318,"coupon_discount_amount":0,"store_discount_amount":0,"total_tax_amount":0,"delivery_charge":200,"dm_tips":0,"additional_charge":10,"flash_admin_discount_amount":60,"flash_store_discount_amount":60,"extra_packaging_amount":0,"ref_bonus_amount":0,"bring_change_amount":0,"payment_status":"paid","order_status":"delivered","payment_method":"cash_on_delivery","order_note":null,"order_type":"delivery","charge_payer":null,"prescription_order":false,"tax_status":"included","cancellation_reason":null,"cancellation_note":null,"processing_time":null,"cutlery":false,"unavailable …[truncated]
```

### PUT `api/v1/customer/order/offline-payment`

- **Auth:** `customer_or_guest`
- **Parameters:** `order_id` (**required**), `method_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/customer/order/offline-payment' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"order_id":100024,"method_id":1}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Successfully created","content":null,"errors":[]}
```

### PUT `api/v1/customer/order/offline-payment-update`

- **Auth:** `customer_or_guest`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/customer/order/offline-payment-update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"order_id":100024}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":null,"errors":[]}
```

### GET `api/v1/customer/order/parcel-instructions`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/parcel-instructions' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 5'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":4,"instruction":"Customer instruction for place parcel order"},{"id":5,"instruction":"Customer instruction for place parcel order Customer instruction for place parcel order Customer instruction for place parcel order Customer instruction for place parcel order"},{"id":6,"instruction":"Customer instruction for place parcel order Customer instruction for place parcel order Customer instruction for place parcel order Customer instruction for place parcel order Customer instru"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":3,"from":1,"to":3}},"errors":[]}
```

### POST `api/v1/customer/order/parcel-return`

- **Auth:** `customer_or_guest`
- **Parameters:** `order_id` (**required**), `order_status` (**required**), `return_otp` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/order/parcel-return' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 5' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"order_id":100024,"order_status":"returned","return_otp":"test"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The return otp must be a number.","content":null,"errors":{"return_otp":["The return otp must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/customer/order/payment-failed`

- **Auth:** `customer_or_guest`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/payment-failed' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":null,"errors":[]}
```

### PUT `api/v1/customer/order/payment-method`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/customer/order/payment-method' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/customer/order/place`

- **Auth:** `customer_or_guest`
- **Parameters:** `payment_method` (**required**), `order_type` (**required**), `store_id` (conditional — `required_unless:order_type,parcel`), `distance` (conditional — `required_unless:order_type,take_away`), `address` (conditional — `required_unless:order_type,take_away`), `longitude` (conditional — `required_unless:order_type,take_away`), `latitude` (conditional — `required_unless:order_type,take_away`), `parcel_category_id` (conditional — `required_if:order_type,parcel`), `receiver_details` (conditional — `required_if:order_type,parcel`), `charge_payer` (conditional — `required_if:order_type,parcel`), `dm_tips` (optional), `guest_id` (**required**), `contact_person_name` (**required**), `contact_person_number` (**required**), `contact_person_email` (**required**), `password` (optional), `monthly_subscribe` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/order/place' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"payment_method":"cash_on_delivery","order_type":"take_away","store_id":3,"distance":1,"address":"test","longitude":"90.425614","latitude":"23.735129","parcel_category_id":1,"receiver_details":"test","charge_payer":"sender","dm_tips":"test","guest_id":"1","contact_person_name":"test","contact_person_number":"+8801700000000","contact_person_email":"6amtech@gmail.com","password":"Str0ng@Pass1","monthly_subscribe":"test"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The dm tips must be a number.","content":null,"errors":{"dm_tips":["The dm tips must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/customer/order/prescription/place`

- **Auth:** `customer_or_guest`
- **Parameters:** `payment_method` (**required**), `order_type` (**required**), `store_id` (conditional — `required_unless:order_type,parcel`), `distance` (conditional — `required_unless:order_type,take_away`), `address` (conditional — `required_unless:order_type,take_away`), `longitude` (conditional — `required_unless:order_type,take_away`), `latitude` (conditional — `required_unless:order_type,take_away`), `parcel_category_id` (conditional — `required_if:order_type,parcel`), `receiver_details` (conditional — `required_if:order_type,parcel`), `charge_payer` (conditional — `required_if:order_type,parcel`), `dm_tips` (optional), `guest_id` (**required**), `contact_person_name` (**required**), `contact_person_number` (**required**), `contact_person_email` (**required**), `password` (optional), `monthly_subscribe` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/order/prescription/place' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"payment_method":"cash_on_delivery","order_type":"take_away","store_id":3,"distance":1,"address":"test","longitude":"90.425614","latitude":"23.735129","parcel_category_id":1,"receiver_details":"test","charge_payer":"sender","dm_tips":"test","guest_id":"1","contact_person_name":"test","contact_person_number":"+8801700000000","contact_person_email":"6amtech@gmail.com","password":"Str0ng@Pass1","monthly_subscribe":"test"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The dm tips must be a number.","content":null,"errors":{"dm_tips":["The dm tips must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/customer/order/refund-reasons`

- **Auth:** `customer_or_guest`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/refund-reasons' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":5,"reason":"The Product Was Damaged Upon Arrival."},{"id":6,"reason":"The Merchant Shipped the Wrong Item."},{"id":7,"reason":"fdghfthyt"},{"id":8,"reason":"Test"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":4,"from":1,"to":4}},"errors":[]}
```

### POST `api/v1/customer/order/refund-request`

- **Auth:** `customer_or_guest`
- **Parameters:** `order_id` (**required**), `customer_reason` (**required**), `refund_method` (optional), `customer_note` (optional), `image` (optional), `image.*` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/order/refund-request' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"order_id":100024,"customer_reason":"test","refund_method":"test","customer_note":"test","image":[]}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"order","message":"You can not request for a refund"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/customer/order/running-orders`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/running-orders?guest_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":103008,"user_id":8,"order_amount":176.08,"coupon_discount_amount":20.25,"store_discount_amount":3,"total_tax_amount":0,"delivery_charge":150,"dm_tips":10,"additional_charge":10,"flash_admin_discount_amount":0,"flash_store_discount_amount":0,"extra_packaging_amount":0,"ref_bonus_amount":0,"bring_change_amount":0,"payment_status":"unpaid","order_status":"pending","payment_method":"cash_on_delivery","order_note":null,"order_type":"delivery","charge_payer":null,"prescription_order":false,"tax_status":"included","cancellation_reason":null,"cancellation_note":null,"processing_time":null,"cutlery":true,"unavai …[truncated]
```

### GET `api/v1/customer/order/track`

- **Auth:** `customer_or_guest`
- **Parameters:** `order_id` (**required**), `contact_number` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/order/track?order_id=100024&contact_number=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/customer/order/wallet-payment`

- **Auth:** `customer_or_guest`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/order/wallet-payment' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"order_id":100024}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":null,"errors":[]}
```

### GET `api/v1/customer/pro-customer/active-offer`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/pro-customer/active-offer' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"status":false,"message":"expired","benefit":{"type":"discount","subscription_id":2,"plan_id":9,"percentage":10,"max_amount":10,"min_order_status":0,"min_order_amount":null},"plan_details":{"plan_name":"Best","total_saved":288.773,"total_orders":9,"start_at":"2026-07-28","end_at":"2026-08-07","days_remaining":0,"paid_by":"wallet"}},"errors":[]}
```

### POST `api/v1/customer/pro-customer/cancel`

- **Auth:** `customer`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/pro-customer/cancel' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"no_active_subscription","message":"No active subscription to cancel"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/customer/pro-customer/subscribe`

- **Auth:** `customer`
- **Parameters:** `plan_id` (**required**), `payment_type` (**required**), `payment_method` (conditional — `required_if:payment_type,digital_payment`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/pro-customer/subscribe' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"plan_id":3,"payment_type":"wallet","payment_method":"cash_on_delivery"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"plan_unavailable","message":"Plan not available"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/customer/recent-ordered-items`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/recent-ordered-items' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":57,"name":"Shanghai Bok Choy","slug":"shanghai-bok-choy57","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-10-27-671df6ea1ca72.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671df6ea1bbf6.png"],"price":2.48,"discount":0,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":82,"unit_type":"Kg","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":5,"rating_count":3,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null,"category_ids":[{"id":"12","position":1},{"id":"104","position":2}],"module_id" …[truncated]
```

### GET `api/v1/customer/reels/details`

- **Auth:** `customer_or_guest`
- **Parameters:** `reel_id` (**required**), `guest_id` (**required**), `stream` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/reels/details?reel_id=2&guest_id=1&stream=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
   ftypiso5   iso5iso6mp41  ,moov   lmvhd              ?                                                @                                .trak   \tkhd                                                                    @   h  ?     $edts   elst             ?     ?mdia    mdhd              ?`    ?     Ahdlr        vide            Mainconcept Video Media Handler   =minf   vmhd              $dinf   dref           url       ?stbl   ?stsd          ?avc1                       h? H   H       Lavc60.31.102 libx264           ??   8avcCd ?? gd ?فpQ?? (  H ? x??? h?x\?,???    colrnclx       stts           stsc           stsz               stco         …[truncated]
```

### POST `api/v1/customer/reels/like`

- **Auth:** `customer`
- **Parameters:** `reel_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/reels/like' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"reel_id":2}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Unliked successfully","content":{"total_views":43,"total_likes":0,"total_store_visits":2,"total_sale":2,"total_sale_amount":49,"is_liked":0,"liked":false},"errors":[]}
```

### GET `api/v1/customer/reels/list`

- **Auth:** `customer_or_guest`
- **Parameters:** `store_id` (optional), `limit` (optional), `page` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/reels/list?store_id=1&limit=10&page=1&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"reel_id":2,"description":"h","thumbnail_full_url":"{{host}}\/storage\/app\/public\/reels\/2026-06-09-6a27ba4a05ded.webp","store_id":1,"store_name":"Organic Shop","store_logo_full_url":"{{host}}\/storage\/app\/public\/store\/2026-06-21-6a3787aa768d2.webp","product_type":"item","product_id":448,"item_id":448,"vehicle_id":null,"service_id":null,"order_now_button":true,"item":{"id":448,"name":"potato chips","price":10,"image_full_url":null,"store_id":1},"service":null,"vehicle":null,"verified_seller":1,"stats":{"total_views":43,"total_likes":0,"total_store_visits":2,"total_sale":2,"total_sale_amount":49,"is_lik …[truncated]
```

### GET `api/v1/customer/reels/stats`

- **Auth:** `customer_or_guest`
- **Parameters:** `reel_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/reels/stats?reel_id=2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_views":43,"total_likes":0,"total_store_visits":2,"total_sale":2,"total_sale_amount":49,"is_liked":0,"liked":false},"errors":[]}
```

### POST `api/v1/customer/reels/visit`

- **Auth:** `customer_or_guest`
- **Parameters:** `reel_id` (**required**), `guest_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/reels/visit' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"reel_id":2,"guest_id":"1"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully updated","content":{"total_views":43,"total_likes":0,"total_store_visits":2,"total_sale":2,"total_sale_amount":49,"is_liked":0,"liked":false},"errors":[]}
```

### DELETE `api/v1/customer/remove-account`

- **Auth:** `customer`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/customer/remove-account' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"on-going","message":"Please complete your ongoing and accepted orders"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/customer/review-reminder`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/review-reminder' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"order_id":103013,"images":["{{host}}\/storage\/app\/public\/product\/2024-10-31-67233a7fdc39f.png"]},"errors":[]}
```

### GET `api/v1/customer/review-reminder-cancel`

- **Auth:** `customer`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/review-reminder-cancel?order_id=100024' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/customer/saved-files`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/saved-files' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### DELETE `api/v1/customer/saved-files/delete-all`

- **Auth:** `customer`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/customer/saved-files/delete-all' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":null,"errors":[]}
```

### POST `api/v1/customer/saved-files/store`

- **Auth:** `customer`
- **Parameters:** `saved_images` (**required**), `saved_images.*` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/saved-files/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"saved_images":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The saved images field is required.","content":null,"errors":{"saved_images":["The saved images field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/customer/suggested-items`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/suggested-items' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":372,"name":"Bathroom Foam Cleaner","slug":"bathroom-foam-cleaner","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-11-17-6739a6cf41c85.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-11-17-6739a6cf3f416.png","{{host}}\/storage\/app\/public\/product\/2024-11-17-6739a6cf40ba7.png","{{host}}\/storage\/app\/public\/product\/2024-11-17-6739a6cf41471.png"],"price":25,"discount":0,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":495,"unit_type":"Pcs","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_ …[truncated]
```

### POST `api/v1/customer/update-interest`

- **Auth:** `customer`
- **Parameters:** `interest` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/update-interest' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"interest":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The interest field is required.","content":null,"errors":{"interest":["The interest field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/customer/update-profile`

- **Auth:** `customer`
- **Parameters:** `name` (**required**), `email` (**required**), `phone` (**required**), `image` (optional), `password` (optional), `session_info` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/update-profile' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"name":"Audit Probe","email":"6amtech@gmail.com","phone":"+8801700000000","password":"Str0ng@Pass1","session_info":"test"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":{"message":"Profile successfully updated"},"errors":[]}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### GET `api/v1/customer/update-zone`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/update-zone' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":null,"errors":[]}
```

### GET `api/v1/customer/visit-again`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/visit-again' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"name":"Organic Shop","slug":"organic-shop1","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2026-06-21-6a3787aa768d2.webp","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2026-07-11-6a5207c2c04a0.webp","module_id":1,"module_type":"grocery","avg_rating":3.67,"reviews_count":null,"items_count":18,"category_ids":[131,129,157,156,63,1,142,102,104,12],"category_names":["Spices","test testtrye","Wipes","Ghee","Vegetables"],"delivery_time":"10-52 min","min_delivery_time":10,"max_delivery_time":52,"distance":49713.255488951676,"distance_km":49.71,"open":1,"current_opening_time": …[truncated]
```

### POST `api/v1/customer/wallet/add-fund`

- **Auth:** `customer`
- **Parameters:** `amount` (**required**), `payment_method` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/wallet/add-fund' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"amount":100,"payment_method":"cash_on_delivery"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/customer/wallet/bonuses`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/wallet/bonuses' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"title":"Well known services","bonus_type":"percentage","bonus_amount":10,"minimum_add_amount":100,"end_date":"2028-07-29T18:00:00.000000Z"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### GET `api/v1/customer/wallet/transactions`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/wallet/transactions' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"credit":27.5,"debit":0,"admin_bonus":0,"transaction_type":"order_refund","reference":"100024","created_at":"2026-08-27 14:13:04"},{"credit":27.5,"debit":0,"admin_bonus":0,"transaction_type":"order_refund","reference":"100024","created_at":"2026-08-27 13:58:54"},{"credit":27.5,"debit":0,"admin_bonus":0,"transaction_type":"order_refund","reference":"100024","created_at":"2026-08-27 13:57:30"},{"credit":27.5,"debit":0,"admin_bonus":0,"transaction_type":"order_refund","reference":"100024","created_at":"2026-08-27 13:55:43"},{"credit":27.5,"debit":0,"admin_bonus":0,"transaction_type":"order_refund","reference":" …[truncated]
```

### GET `api/v1/customer/wish-list`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/customer/wish-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"item":[{"id":22,"name":"Choco Chip Cookies","slug":"annas-clover-honey22","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd0b4d3.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd09ae0.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd0a45a.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd0aab9.png"],"price":2,"discount":20,"discount_type":"percent","store_discount":0,"flash_sale":1,"stock":6,"unit_type":"Pack","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":1,"rating_count":1,"available_time_s …[truncated]
```

### POST `api/v1/customer/wish-list/add`

- **Auth:** `customer`
- **Parameters:** `item_id` (conditional — `required_without_all:store_id,service_id`), `store_id` (conditional — `required_without_all:item_id,service_id`), `service_id` (conditional — `required_without_all:item_id,store_id`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/customer/wish-list/add' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"item_id":101,"store_id":3,"service_id":1}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"data","message":"Can not add both food and restaurant at same time"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/customer/wish-list/remove`

- **Auth:** `customer`
- **Parameters:** `item_id` (conditional — `required_without_all:store_id,service_id`), `store_id` (conditional — `required_without_all:item_id,service_id`), `service_id` (conditional — `required_without_all:item_id,store_id`)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/customer/wish-list/remove' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"item_id":101,"store_id":3,"service_id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### PUT `api/v1/delivery-man/accept-order`

- **Auth:** `deliveryman`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/delivery-man/accept-order' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"order_id":100001,"token":"{{delivery_man_token}}"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Can not accept","content":null,"errors":[{"code":"order","message":"Can not accept"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/delivery-man/add-return-date`

- **Auth:** `deliveryman`
- **Parameters:** `order_id` (**required**), `return_date` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/add-return-date' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"order_id":100001,"return_date":"2026-08-27","token":"{{delivery_man_token}}"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"amount","message":"Order not found"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/delivery-man/all-orders`

- **Auth:** `deliveryman`
- **Parameters:** `order_status` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/all-orders?order_status=test&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":102980,"user_id":334,"order_amount":178.9,"coupon_discount_amount":0,"coupon_discount_title":null,"payment_status":"paid","order_status":"delivered","total_tax_amount":72.9,"payment_method":"wallet","transaction_reference":null,"delivery_address_id":null,"delivery_man_id":1,"coupon_code":null,"order_note":null,"order_type":"parcel","checked":1,"store_id":null,"created_at":"2026-07-28 19:54:08","updated_at":"2026-07-28T14:09:37.000000Z","delivery_charge":81,"delivery_type":"standard","delivery_type_charge":0,"schedule_at":"2026-07-28 19:54:08","callback":null,"otp":"5049","pending":"2026-07-28 19:54:08", …[truncated]
```

### GET `api/v1/delivery-man/convert-loyalty-points`

- **Auth:** `deliveryman`
- **Parameters:** `points` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/convert-loyalty-points?points=10&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Loyalty point converted successfully","content":null,"errors":[]}
```

### GET `api/v1/delivery-man/current-orders`

- **Auth:** `deliveryman`
- **Parameters:** `order_status` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/current-orders?order_status=test&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":100028,"user_id":9,"order_amount":223.3,"coupon_discount_amount":0,"coupon_discount_title":null,"payment_status":"paid","order_status":"delivered","total_tax_amount":20.3,"payment_method":"cash_on_delivery","transaction_reference":null,"delivery_address_id":null,"delivery_man_id":1,"coupon_code":null,"order_note":null,"order_type":"delivery","checked":1,"store_id":12,"created_at":"2022-09-29 18:32:43","updated_at":"2022-09-29T15:48:54.000000Z","delivery_charge":0,"delivery_type":null,"delivery_type_charge":0,"schedule_at":"2022-09-29 18:32:43","callback":null,"otp":"9932","pending":null,"accepted":"2022 …[truncated]
```

### GET `api/v1/delivery-man/earning-report`

- **Auth:** `deliveryman`
- **Parameters:** `start_date` (optional), `end_date` (optional), `type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/earning-report?start_date=2026-08-27&end_date=2026-08-27&type=all&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_dm_tips":801,"total_delivery_charge":97890.06,"total_admin_commission":2680.900000000002,"total_loyalty_point_earning":17.339999999999993,"total_referal":80,"type":"all","data":[{"id":466,"order_id":102980,"delivery_man_id":1,"dm_tips":15,"original_delivery_charge":45,"delivery_fee_comission":0,"created_at":"2026-07-28T13:54:43.000000Z","order":{"id":102980,"payment_method":"wallet","module_type":null,"order_attachment_full_url":[],"order_proof_full_url":[],"module":null}},{"id":465,"order_id":102979,"delivery_man_id":1,"dm_tips":0,"original_delivery_charge":135,"delivery_fee_comission":15,"created_at":"2026-0 …[truncated]
```

### GET `api/v1/delivery-man/get-disbursement-report`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/get-disbursement-report?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"pending":8467.77,"completed":8308.86,"canceled":0,"complete_day":8,"data":[{"id":25,"disbursement_id":1019,"store_id":null,"delivery_man_id":1,"disbursement_amount":117.16,"payment_method":18,"status":"pending","created_at":"2026-07-27T13:34:06.000000Z","updated_at":"2026-07-27T13:34:06.000000Z","delivery_man":{"id":1,"f_name":"Jhon","l_name":"Doe","phone":"+8801700000000","email":"deliveryman@6amtech.com","identity_number":"98900000","identity_type":"passport","identity_image":"[\"2022-09-29-63351bf7335cc.png\",{\"img\":\"2025-12-02-692ebf4bd876d.jpeg\",\"storage\":\"public\"},{\"img\":\"2025-12-02-692ebf4bd8cf8.jp …[truncated]
```

### GET `api/v1/delivery-man/get-withdraw-list`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/get-withdraw-list?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":62,"vendor_id":null,"admin_id":null,"transaction_note":null,"amount":12645.25,"updated_at":"2026-07-14T15:08:27.000000Z","delivery_man_id":1,"withdrawal_method_id":1,"withdrawal_method_fields":"{\"account_name\":\"Sabrina\",\"account_number\":\"1234567\",\"email\":null}","type":"manual","sender_note":null,"user_note":null,"status":"Pending","requested_at":"2026-07-14 21:08:27","bank_name":"Card","detail":{"account_name":"Sabrina","account_number":"1234567","email":null},"method":{"id":1,"method_name":"Card","method_fields":[{"input_type":"string","input_name":"account_name","placeholder":"Enter your car …[truncated]
```

### GET `api/v1/delivery-man/get-withdraw-method-list`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/get-withdraw-method-list?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"method_name":"Card","method_fields":[{"input_type":"string","input_name":"account_name","placeholder":"Enter your card holder name","is_required":1},{"input_type":"number","input_name":"account_number","placeholder":"Enter your account number","is_required":1},{"input_type":"email","input_name":"email","placeholder":"Enter your account email","is_required":0}],"is_default":1,"is_active":1,"created_at":"2023-11-27T12:22:06.000000Z","updated_at":"2023-11-27T12:22:06.000000Z"},{"id":2,"method_name":"6cash","method_fields":[{"input_type":"string","input_name":"account_name","placeholder":"Enter your acco …[truncated]
```

### GET `api/v1/delivery-man/income-statement`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/income-statement?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":6,"vendor_id":45,"delivery_man_id":1,"order_id":100039,"order_amount":"4012.65","store_amount":"247.50","admin_commission":"0.00","received_by":"admin","status":null,"created_at":"2022-09-29T14:41:46.000000Z","updated_at":"2022-09-29T14:41:46.000000Z","delivery_charge":"3765.15","original_delivery_charge":"3765.15","tax":"22.50","zone_id":1,"module_id":4,"parcel_catgory_id":null,"dm_tips":0,"delivery_fee_comission":0,"admin_expense":"0.000","store_expense":0,"discount_amount_by_store":0,"additional_charge":0,"extra_packaging_amount":0,"ref_bonus_amount":0,"commission_percentage":0,"is_subscribed":0,"pro …[truncated]
```

### GET `api/v1/delivery-man/last-location`

- **Auth:** `public`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/last-location?order_id=100024' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":null,"errors":[]}
```

### GET `api/v1/delivery-man/latest-orders`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/latest-orders?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":102995,"user_id":391,"order_amount":1444,"coupon_discount_amount":0,"coupon_discount_title":"","payment_status":"paid","order_status":"confirmed","total_tax_amount":214,"payment_method":"ssl_commerz","transaction_reference":null,"delivery_address_id":null,"delivery_man_id":null,"coupon_code":null,"order_note":null,"order_type":"delivery","checked":1,"store_id":34,"created_at":"2026-07-29 16:21:07","updated_at":"2026-07-29T10:51:33.000000Z","delivery_charge":150,"delivery_type":"standard","delivery_type_charge":0,"schedule_at":"2026-07-29 16:21:07","callback":null,"otp":"9015","pending":"2026-07-29 16:21 …[truncated]
```

### GET `api/v1/delivery-man/loyalty-point-list`

- **Auth:** `deliveryman`
- **Parameters:** `start_date` (optional), `end_date` (optional), `type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/loyalty-point-list?start_date=2026-08-27&end_date=2026-08-27&type=credit&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":176,"transaction_id":"176DOW77OC","transaction_type":"earn_on_order_completion","converted_amount":0,"point":10,"created_at":"2026-07-28T13:54:43.000000Z","reference":"102980","point_conversion_type":"credit"},{"id":175,"transaction_id":"1753J7ZRYM","transaction_type":"earn_on_order_completion","converted_amount":0,"point":10,"created_at":"2026-07-28T13:40:20.000000Z","reference":"102979","point_conversion_type":"credit"},{"id":174,"transaction_id":"174SSW0PVL","transaction_type":"earn_on_order_completion","converted_amount":0,"point":10,"created_at":"2026-07-28T13:18:57.000000Z","reference":"102977","p …[truncated]
```

### GET `api/v1/delivery-man/loyalty-report`

- **Auth:** `deliveryman`
- **Parameters:** `start_date` (optional), `end_date` (optional), `type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/loyalty-report?start_date=2026-08-27&end_date=2026-08-27&type=all&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_dm_tips":801,"total_delivery_charge":97890.06,"total_admin_commission":2680.900000000002,"total_loyalty_point_earning":17.339999999999993,"total_referal":80,"type":"all","data":[{"id":239,"transaction_id":"239GEHWEOP","transaction_type":"converted_to_wallet","converted_amount":0.02,"point":10,"created_at":"2026-08-27T08:13:08.000000Z"},{"id":238,"transaction_id":"2389JMPPLD","transaction_type":"converted_to_wallet","converted_amount":0.02,"point":10,"created_at":"2026-08-27T07:58:58.000000Z"},{"id":237,"transaction_id":"237DM5J74L","transaction_type":"converted_to_wallet","converted_amount":0.02,"point":10,"cr …[truncated]
```

### POST `api/v1/delivery-man/make-collected-cash-payment`

- **Auth:** `deliveryman`
- **Parameters:** `payment_gateway` (**required**), `amount` (**required**), `callback` (**required**), `token` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/make-collected-cash-payment' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"payment_gateway":"test","amount":100,"callback":"test","token":"{{delivery_man_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"redirect_link":""},"errors":[]}
```

### POST `api/v1/delivery-man/make-wallet-adjustment`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/make-wallet-adjustment' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"token":"{{delivery_man_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Delivery man wallet adjustment successful","content":null,"errors":[]}
```

### GET `api/v1/delivery-man/message/details`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/message/details?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"status":true,"conversation":null,"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/delivery-man/message/list`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/message/list?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":70,"sender_type":"delivery_man","receiver_type":"admin","unread_message_count":23,"last_message_time":"2026-08-27 13:59:01","sender":{"id":4,"f_name":"Audit","l_name":"Probe","phone":"+8801700000000","image_full_url":"{{host}}\/storage\/app\/public\/delivery-man\/2022-09-29-63351bf73345f.png"},"receiver":null,"last_message":{"sender_id":3,"message":null,"file_full_url":[],"is_seen":0,"created_at":"2026-08-27T07:59:01.000000Z"}},{"id":14,"sender_type":"customer","receiver_type":"delivery_man","unread_message_count":0,"last_message_time":"2026-07-11 23:25:07","sender":{"id":16,"f_name":"Audit","l_name":"P …[truncated]
```

### POST `api/v1/delivery-man/message/question/send`

- **Auth:** `deliveryman`
- **Parameters:** `question_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/message/question/send' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"question_id":1,"token":"{{delivery_man_token}}"}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Successfully created","content":{"status":true,"conversation":{"id":70,"sender_type":"delivery_man","receiver_type":"admin","unread_message_count":24,"last_message_time":"2026-08-27 14:13:11","sender":{"id":4,"f_name":"Audit","l_name":"Probe","phone":"+8801700000000","image_full_url":"{{host}}\/storage\/app\/public\/delivery-man\/2022-09-29-63351bf73345f.png"},"receiver":null,"last_message":{"sender_id":3,"message":null,"file_full_url":[],"is_seen":0,"created_at":"2026-08-27T08:13:11.000000Z"}},"data":[{"sender_id":3,"message":null,"file_full_url":[],"is_seen":0,"created_at":"2026-08-27T08:13:11.000000Z"},{"sender_id":4,"message":null,"file_fu …[truncated]
```

### GET `api/v1/delivery-man/message/search-list`

- **Auth:** `deliveryman`
- **Parameters:** `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/message/search-list?name=Ferrero&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### POST `api/v1/delivery-man/message/send`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/message/send' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"token":"{{delivery_man_token}}"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Validation failed","content":null,"errors":[{"code":"receiver_id","message":"Invalid receiver"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/delivery-man/new-earning-report`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/new-earning-report?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"summary":{"total_earnings":110329.68,"total_earnings_percentage":100,"total_earnings_positive":true,"total_expenses":11725.629999999992,"total_expenses_percentage":100,"total_expenses_positive":true,"net_profit":98604.05,"net_profit_percentage":100,"net_profit_positive":true,"breakdown":{"delivery_charge":97818.05,"delivery_charge_percentage":99.2,"delivery_charge_positive":true,"dm_tips":786,"dm_tips_percentage":0.8,"dm_tips_positive":true,"admin_commission_percentage":100,"admin_commission_positive":true}},"trends":{"categories":["Sep","Oct","Nov","Dec","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug"],"earning_ser …[truncated]
```

### GET `api/v1/delivery-man/notifications`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/notifications?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":25928,"data":{"title":"Order","description":"You are assigned to a order","order_id":100028,"image":"","type":"assign"},"status":1,"user_id":null,"vendor_id":null,"delivery_man_id":1,"serviceman_id":null,"order_type":null,"created_at":"2026-08-27 13:53:20","updated_at":"2026-08-27T07:53:20.000000Z"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### GET `api/v1/delivery-man/order`

- **Auth:** `deliveryman`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/order?order_id=100001&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":100001,"user_id":3,"order_amount":5770.28,"coupon_discount_amount":0,"coupon_discount_title":"","payment_status":"paid","order_status":"delivered","total_tax_amount":8.28,"payment_method":"cash_on_delivery","transaction_reference":null,"delivery_address_id":null,"delivery_man_id":1,"coupon_code":null,"order_note":null,"order_type":"delivery","checked":1,"store_id":11,"created_at":"2022-03-22 23:48:32","updated_at":"2026-08-27T07:59:01.000000Z","delivery_charge":5679.2,"delivery_type":null,"delivery_type_charge":0,"schedule_at":"2022-03-22 23:48:32","callback":null,"otp":"7252","pending":"2022-03-22 23:48:32","ac …[truncated]
```

### GET `api/v1/delivery-man/order-delivery-history`

- **Auth:** `deliveryman`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/order-delivery-history?order_id=100001&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/delivery-man/order-details`

- **Auth:** `deliveryman`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/order-details?order_id=100001&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[{"id":1,"item_id":24,"order_id":100001,"price":90,"item_details":{"id":24,"name":"Suruchi Premium Green Chili Pickle","description":"It\u2019s a variety of pickle offers by Suruchi Spices Pvt. Ltd. for the green chilli lovers. This product adds on a distinct taste, can me served with any Snacks, meals etc","image":"2022-03-22-6239a7117c441.png","category_id":5,"category_ids":[{"id":"5","position":1}],"variations":[],"add_ons":[],"attributes":[],"choice_options":[],"price":90,"tax":10,"tax_type":"percent","discount":8,"discount_type":"percent","available_time_starts":"12:00:00","available_time_ends":"11:59:00","veg":0 …[truncated]
```

### GET `api/v1/delivery-man/orders-count`

- **Auth:** `deliveryman`
- **Parameters:** `type` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/orders-count?type=current&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[{"key":"all","count":59},{"key":"accepted","count":32},{"key":"confirmed","count":14},{"key":"pending","count":0},{"key":"processing","count":1},{"key":"picked_up","count":10},{"key":"handover","count":2}],"errors":[]}
```

### POST `api/v1/delivery-man/parcel-return`

- **Auth:** `deliveryman`
- **Parameters:** `order_id` (**required**), `order_status` (**required**), `return_otp` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/parcel-return' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 5' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"order_id":100001,"order_status":"returned","return_otp":"test","token":"{{delivery_man_token}}"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The return otp must be a number.","content":null,"errors":{"return_otp":["The return otp must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/delivery-man/parcel-return-earning-list`

- **Auth:** `deliveryman`
- **Parameters:** `start_date` (optional), `end_date` (optional), `type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/parcel-return-earning-list?start_date=2026-08-27&end_date=2026-08-27&type=all&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 5' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":28,"transaction_id":"28CTGFKEP8","order_id":101746,"amount":"25.20000","created_at":"2026-02-10T14:56:58.000000Z"},{"id":20,"transaction_id":"20DFUILJTY","order_id":101267,"amount":"26.70400","created_at":"2026-02-02T09:22:15.000000Z"},{"id":21,"transaction_id":"21S90XKMNV","order_id":101273,"amount":"33.46600","created_at":"2026-02-02T09:22:15.000000Z"},{"id":22,"transaction_id":"226UYDYF4D","order_id":101364,"amount":"18.00000","created_at":"2026-02-02T09:22:15.000000Z"},{"id":23,"transaction_id":"23WASQFWIL","order_id":101366,"amount":"22.77600","created_at":"2026-02-02T09:22:15.000000Z"},{"id":24,"t …[truncated]
```

### GET `api/v1/delivery-man/profile`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/profile?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":1,"f_name":"Jhon","l_name":"Doe","phone":"+8801700000000","email":"deliveryman@6amtech.com","identity_number":"98900000","identity_type":"passport","identity_image":"[\"2022-09-29-63351bf7335cc.png\",{\"img\":\"2025-12-02-692ebf4bd876d.jpeg\",\"storage\":\"public\"},{\"img\":\"2025-12-02-692ebf4bd8cf8.jpeg\",\"storage\":\"public\"},{\"img\":\"2025-12-02-692ebf4bd8d8e.jpeg\",\"storage\":\"public\"},{\"img\":\"2025-12-02-692ebf4bd8e1d.jpeg\",\"storage\":\"public\"}]","image":"2022-09-29-63351bf73345f.png","fcm_token":null,"zone_id":1,"created_at":"2022-03-30T07:14:16.000000Z","updated_at":"2026-08-27T08:13:08.0000 …[truncated]
```

### POST `api/v1/delivery-man/record-location-data`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/record-location-data' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"token":"{{delivery_man_token}}"}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Location recorded","content":null,"errors":[]}
```

### GET `api/v1/delivery-man/referral-earning-list`

- **Auth:** `deliveryman`
- **Parameters:** `start_date` (optional), `end_date` (optional), `type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/referral-earning-list?start_date=2026-08-27&end_date=2026-08-27&type=all&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":8,"transaction_id":"8P1XDSSMOY","amount":20,"created_at":"2025-12-14T12:42:48.000000Z"},{"id":6,"transaction_id":"675I36DDZB","amount":20,"created_at":"2025-12-14T10:11:24.000000Z"},{"id":4,"transaction_id":"4PEOUGBZB6","amount":20,"created_at":"2025-12-13T10:27:28.000000Z"},{"id":2,"transaction_id":"8e39799c-4ff0-4ec5-ad82-15c9e5f56932","amount":20,"created_at":"2025-12-09T12:36:19.000000Z"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":4,"from":1,"to":4}},"errors":[]}
```

### GET `api/v1/delivery-man/referral-report`

- **Auth:** `deliveryman`
- **Parameters:** `start_date` (optional), `end_date` (optional), `type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/referral-report?start_date=2026-08-27&end_date=2026-08-27&type=all&token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_dm_tips":801,"total_delivery_charge":97890.06,"total_admin_commission":2680.900000000002,"total_loyalty_point_earning":17.339999999999993,"total_referal":80,"type":"all","data":[{"id":8,"transaction_id":"8P1XDSSMOY","amount":20,"created_at":"2025-12-14T12:42:48.000000Z"},{"id":6,"transaction_id":"675I36DDZB","amount":20,"created_at":"2025-12-14T10:11:24.000000Z"},{"id":4,"transaction_id":"4PEOUGBZB6","amount":20,"created_at":"2025-12-13T10:27:28.000000Z"},{"id":2,"transaction_id":"8e39799c-4ff0-4ec5-ad82-15c9e5f56932","amount":20,"created_at":"2025-12-09T12:36:19.000000Z"}],"pagination":{"current_page":1,"last …[truncated]
```

### DELETE `api/v1/delivery-man/remove-account`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/delivery-man/remove-account' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"token":"{{delivery_man_token}}"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"on-going","message":"Please complete your ongoing and accepted orders"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/delivery-man/request-withdraw`

- **Auth:** `deliveryman`
- **Parameters:** `amount` (**required**), `id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/request-withdraw' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"amount":100,"id":1,"token":"{{delivery_man_token}}"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Insufficient balance","content":null,"errors":[{"code":"amount","message":"Insufficient balance"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/delivery-man/reviews/rating/{delivery_man_id}`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/reviews/rating/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"average_rating":4},"errors":[]}
```

### POST `api/v1/delivery-man/reviews/submit`

- **Auth:** `customer`
- **Parameters:** `delivery_man_id` (**required**), `order_id` (**required**), `comment` (**required**), `rating` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/reviews/submit' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"delivery_man_id":1,"order_id":100024,"comment":"test","rating":"test"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The rating must be a number.","content":null,"errors":{"rating":["The rating must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/delivery-man/reviews/{delivery_man_id}`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/reviews/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":5,"delivery_man_id":1,"user_id":8,"order_id":101208,"comment":"Good","attachment":[],"rating":5,"created_at":"2025-12-14T18:13:13.000000Z","updated_at":"2025-12-14T18:13:13.000000Z","status":1,"customer":{"id":8,"tenant_id":0,"sub_tenant_id":0,"f_name":"Audit","l_name":"Probe","phone":"+8801700000000","email":"6amtech@gmail.com","image":"2026-07-02-6a45fd3b80ee9.webp","is_phone_verified":1,"email_verified_at":null,"created_at":"2022-03-23T16:53:45.000000Z","updated_at":"2026-08-27T08:13:06.000000Z","user_context":"This customer is in the value spending tier, frequently purchasing mid-range products like …[truncated]
```

### PUT `api/v1/delivery-man/send-order-otp`

- **Auth:** `deliveryman`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/delivery-man/send-order-otp' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"order_id":100001,"token":"{{delivery_man_token}}"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"order","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/delivery-man/update-active-status`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/update-active-status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"token":"{{delivery_man_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Active status updated","content":null,"errors":[]}
```

### PUT `api/v1/delivery-man/update-fcm-token`

- **Auth:** `deliveryman`
- **Parameters:** `fcm_token` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/delivery-man/update-fcm-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"fcm_token":"test","token":"{{delivery_man_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated!","content":null,"errors":[]}
```

### PUT `api/v1/delivery-man/update-order-status`

- **Auth:** `deliveryman`
- **Parameters:** `order_id` (**required**), `status` (**required**), `reason` (conditional — `required_if:status,canceled`), `order_proof` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/delivery-man/update-order-status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"order_id":100001,"status":"confirmed","reason":"audit probe","order_proof":[],"token":"{{delivery_man_token}}"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Order confirmation warning","content":null,"errors":[{"code":"order-confirmation-model","message":"Order confirmation warning"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/delivery-man/update-payment-status`

- **Auth:** `deliveryman`
- **Parameters:** `order_id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/delivery-man/update-payment-status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"order_id":100001,"status":"paid","token":"{{delivery_man_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Payment status updated","content":null,"errors":[]}
```

### PUT `api/v1/delivery-man/update-profile`

- **Auth:** `deliveryman`
- **Parameters:** `f_name` (**required**), `l_name` (**required**), `email` (**required**), `password` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/delivery-man/update-profile' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"f_name":"Audit","l_name":"Probe","email":"deliveryman@6amtech.com","password":"Str0ng@Pass1","token":"{{delivery_man_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated!","content":null,"errors":[]}
```

### GET `api/v1/delivery-man/wallet-payment-list`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/wallet-payment-list?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":294,"from_type":"deliveryman","from_id":1,"current_balance":0,"amount":10262.62,"method":"ssl_commerz","ref":"deliveryman_collect_cash_payments","created_at":"2026-07-14T15:03:48.000000Z","updated_at":"2026-07-14T15:03:48.000000Z","type":"collected","created_by":"deliveryman","status":"approved","payment_time":"14 Jul 2026 09:03:pm"},{"id":293,"from_type":"deliveryman","from_id":1,"current_balance":10262.62,"amount":10262.62,"method":"ssl_commerz","ref":"deliveryman_collect_cash_payments","created_at":"2026-07-14T15:03:38.000000Z","updated_at":"2026-07-14T15:03:38.000000Z","type":"collected","created_by …[truncated]
```

### GET `api/v1/delivery-man/wallet-provided-earning-list`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/wallet-provided-earning-list?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":107,"delivery_man_id":1,"amount":0.02,"method":"adjustment","ref":"delivery_man_wallet_adjustment_partial","created_at":"2026-08-27T08:13:09.000000Z","updated_at":"2026-08-27T08:13:09.000000Z","status":"Approved","payment_time":"27 Aug 2026 02:13:pm"},{"id":106,"delivery_man_id":1,"amount":0.02,"method":"adjustment","ref":"delivery_man_wallet_adjustment_partial","created_at":"2026-08-27T07:58:59.000000Z","updated_at":"2026-08-27T07:58:59.000000Z","status":"Approved","payment_time":"27 Aug 2026 01:58:pm"},{"id":105,"delivery_man_id":1,"amount":0.02,"method":"adjustment","ref":"delivery_man_wallet_adjustm …[truncated]
```

### DELETE `api/v1/delivery-man/withdraw-method/delete`

- **Auth:** `deliveryman`
- **Parameters:** `id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/delivery-man/withdraw-method/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"id":1,"token":"{{delivery_man_token}}"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/delivery-man/withdraw-method/list`

- **Auth:** `deliveryman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/delivery-man/withdraw-method/list?token={{delivery_man_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":101,"store_id":null,"delivery_man_id":1,"withdrawal_method_id":1,"method_name":"Card","method_fields":[],"is_default":false,"created_at":"2026-08-27T07:59:02.000000Z","updated_at":"2026-08-27T07:59:02.000000Z"},{"id":99,"store_id":null,"delivery_man_id":1,"withdrawal_method_id":1,"method_name":"Card","method_fields":[],"is_default":false,"created_at":"2026-08-27T07:57:38.000000Z","updated_at":"2026-08-27T07:57:38.000000Z"},{"id":97,"store_id":null,"delivery_man_id":1,"withdrawal_method_id":1,"method_name":"Card","method_fields":[],"is_default":false,"created_at":"2026-08-27T07:55:52.000000Z","updated_at …[truncated]
```

### POST `api/v1/delivery-man/withdraw-method/make-default`

- **Auth:** `deliveryman`
- **Parameters:** `id` (**required**), `is_default` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/withdraw-method/make-default' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"id":1,"is_default":"test","token":"{{delivery_man_token}}"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/delivery-man/withdraw-method/store`

- **Auth:** `deliveryman`
- **Parameters:** `withdraw_method_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/delivery-man/withdraw-method/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{delivery_man_token}}' \
  -d '{"withdraw_method_id":1,"token":"{{delivery_man_token}}"}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Successfully added!","content":null,"errors":[]}
```

### GET `api/v1/flash-sales`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/flash-sales' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"end_date":"2026-12-31T17:18:00.000000Z","active_products":[{"flash_sale_id":1,"stock":10,"sold":4,"item":{"id":22,"name":"Choco Chip Cookies","slug":"annas-clover-honey22","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd0b4d3.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd09ae0.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd0a45a.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd0aab9.png"],"price":2,"discount":20,"discount_type":"percent","store_discount":0,"flash_sale":1,"stock":6,"unit_type":"Pack","maximum_cart …[truncated]
```

### GET `api/v1/flash-sales/items`

- **Auth:** `public`
- **Parameters:** `flash_sale_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/flash-sales/items?flash_sale_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"flash_sale":{"end_date":"2026-12-31T17:18:00.000000Z","active_products":[]},"data":[{"stock":10,"sold":4,"item":{"id":22,"name":"Choco Chip Cookies","slug":"annas-clover-honey22","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd0b4d3.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd09ae0.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd0a45a.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e15bd0aab9.png"],"price":2,"discount":20,"discount_type":"percent","store_discount":0,"flash_sale":1,"stock":6,"unit_type":"Pack","maxim …[truncated]
```

### GET `api/v1/flutter-landing-page`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/flutter-landing-page' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"base_urls":{"fixed_header_image":"{{host}}\/storage\/app\/public\/fixed_header_image","special_criteria_image":"{{host}}\/storage\/app\/public\/special_criteria","download_user_app_image":"{{host}}\/storage\/app\/public\/download_user_app_image"},"s3_base_urls":{"fixed_header_image":"\/\/fixed_header_image","special_criteria_image":"\/\/special_criteria","download_user_app_image":"\/\/download_user_app_image"},"fixed_header_title":"6amMart","fixed_header_sub_title":"More then just reliable eCommerce","fixed_header_image":"2025-12-28-6950e7e062669.webp","fixed_header_image_full_url":null,"fixed_module_title":"Your eC …[truncated]
```

### GET `api/v1/get-combined-data`

- **Auth:** `public`
- **Parameters:** `list_type` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/get-combined-data?list_type=item' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":10,"name":"Desi Cow Ghee","slug":"mango-50-gm10","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-10-27-671e2b0d89830.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671e2b0d8808e.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e2b0d88b69.png"],"price":40,"discount":10,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":286,"unit_type":"Kg","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":3,"rating_count":1,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{ …[truncated]
```

### GET `api/v1/get-page-meta-data`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/get-page-meta-data' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":null,"errors":[]}
```

### GET `api/v1/get-parcel-cancellation-reasons`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/get-parcel-cancellation-reasons' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 5'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":5,"reason":"Parcel cancellation reason BP D1"},{"id":6,"reason":"Parcel cancellation reason BP D2"},{"id":7,"reason":"Parcel cancellation reason BP C1"},{"id":8,"reason":"Parcel cancellation reason BP C2"},{"id":9,"reason":"Parcel cancellation reason AP D1"},{"id":10,"reason":"Parcel cancellation reason AP C1"},{"id":11,"reason":"Parcel cancellation reason Parcel cancellation reason Parcel cancellation reason Parcel cancellation reason Parcel cancellation AP D1"},{"id":12,"reason":"Parcel cancellation reason Parcel cancellation reason Parcel cancellation reason Parcel cancellation reason Parcel cancella …[truncated]
```

### GET `api/v1/get-vehicles`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/get-vehicles' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"type":"Bicycle","name":null},{"id":2,"type":"Bike","name":null},{"id":3,"type":"cycle","name":null}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":3,"from":1,"to":3}},"errors":[]}
```

### GET `api/v1/item/get-allergy-name-list`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/item/get-allergy-name-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":12,"name":"shshsh"},{"id":13,"name":"tryurt5y6 rtyretyuty"},{"id":14,"name":"5754 5r453 56745 567y45 t56yu4"},{"id":15,"name":"rtyhtryt5r y543 5434 456543"},{"id":16,"name":"ggfdsg"},{"id":17,"name":"57545r45356745567y45t56yu4"},{"id":18,"name":"a"},{"id":19,"name":"ydyd"},{"id":20,"name":"test"},{"id":21,"name":"dudh"},{"id":22,"name":"asdf"},{"id":23,"name":"fgyf"},{"id":24,"name":"tryurt5y6rtyretyuty"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":13,"from":1,"to":13}},"errors":[]}
```

### GET `api/v1/item/get-generic-name-list`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/item/get-generic-name-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"name":"silodosin systemic"},{"id":2,"name":"VItamin A, E D3"},{"id":3,"name":"Povidone-iodine 5%"},{"id":4,"name":"dexlansoprazole"},{"id":5,"name":"acetylsalicylic acid"},{"id":6,"name":"Serum 5% 2 Oz"},{"id":7,"name":"ubiquinone"},{"id":8,"name":"Omeprazol"},{"id":9,"name":"AutoGen"},{"id":10,"name":"InspectGen"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":10,"from":1,"to":10}},"errors":[]}
```

### GET `api/v1/item/get-nutrition-name-list`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/item/get-nutrition-name-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"name":"Calories: Approximately 200-250 kcal"},{"id":2,"name":"Protein: 25-30g"},{"id":3,"name":"Fat: 5-10g"},{"id":4,"name":"Magnesium: 5-8%"},{"id":5,"name":"Vitamin"},{"id":6,"name":"Calories"},{"id":7,"name":"Carbohydrates"},{"id":8,"name":"uu"},{"id":9,"name":"Calories:Approximately200-250kcal"},{"id":10,"name":"Fat:5-10g"},{"id":11,"name":"new"},{"id":12,"name":"ge"},{"id":13,"name":"protein:25-30g"},{"id":14,"name":"yess"},{"id":15,"name":"ggee"},{"id":16,"name":"a"},{"id":17,"name":"s"},{"id":18,"name":"gdhd"},{"id":19,"name":"tets"},{"id":20,"name":"duxbx"},{"id":21,"name":"asd"},{"id":22,"na …[truncated]
```

### GET `api/v1/items/basic`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/basic' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/items/common-conditions`

- **Auth:** `public`
- **Parameters:** `store_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/common-conditions?store_id=3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/items/details/{id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/details/101' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":101,"name":"Ferrero Rocher Chocolate Box","description":"4 delicious Ferrero Rocher chocolate candies, presented in an impressive transparent gift box, the perfect Valentine's Day or Chinese New Year gift for him or her","image":"2022-03-22-6239ceff780fd.png","video":null,"video_link":null,"category_id":11,"category_ids":[{"id":"11","position":1,"name":"Dairy & Eggs"}],"variations":[],"add_ons":[],"attributes":[],"choice_options":[],"price":390,"tax":0,"tax_type":"percent","discount":45,"discount_type":"percent","available_time_starts":"00:00:00","available_time_ends":"23:59:00","veg":0,"status":1,"store_id":3," …[truncated]
```

### GET `api/v1/items/discounted`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/discounted' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":133,"name":"Mazola Corn Oil","slug":"mazola-corn-oil133","image_full_url":null,"images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671e29fb2b1fb.png",null],"price":200,"discount":90,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":586,"unit_type":"Ltr","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"102","position":1},{"id":"140","position":2}],"module_id":1,"module_type":"grocery","store_id":5,"store_name":"Family  …[truncated]
```

### GET `api/v1/items/get-products`

- **Auth:** `public`
- **Parameters:** `category_ids` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/get-products?category_ids%5B0%5D=2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/items/item-or-store-search`

- **Auth:** `public`
- **Parameters:** `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/item-or-store-search?name=Organic' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"stores":[{"id":1,"name":"Organic Shop","logo":"2026-06-21-6a3787aa768d2.webp","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2026-06-21-6a3787aa768d2.webp","module_id":1,"open":1,"distance":49713.255488951676,"distance_km":49.71,"module":{"id":1,"name":"Grocery","image":"{{host}}\/storage\/app\/public\/module\/2026-06-10-6a28dd6a5a82b.webp","type":"grocery"}}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### GET `api/v1/items/latest`

- **Auth:** `public`
- **Parameters:** `store_id` (**required**), `category_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/latest?store_id=3&category_id=2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":115,"name":"Praise Daily Style Mayonnaise","slug":"praise-daily-style-mayonnaise115","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b964484.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b963233.png"],"price":230,"discount":30,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1996,"unit_type":"Ltr","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"2","position":1},{"id":"134 …[truncated]
```

### GET `api/v1/items/most-reviewed`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/most-reviewed' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":57,"name":"Shanghai Bok Choy","slug":"shanghai-bok-choy57","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-10-27-671df6ea1ca72.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671df6ea1bbf6.png"],"price":2.48,"discount":0,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":82,"unit_type":"Kg","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":5,"rating_count":3,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null,"category_ids":[{"id":"12","position":1},{"id":"104","position":2}],"module_id" …[truncated]
```

### GET `api/v1/items/new-arrival`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/new-arrival' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":495,"name":"Spices ffghfh fgth frthrthgr t","slug":"spices","image_full_url":"{{host}}\/storage\/app\/public\/product\/2026-06-28-6a40ff2fb8023.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2026-06-28-6a40ff2fb9622.png"],"price":15.99,"discount":0,"discount_type":"amount","store_discount":0,"flash_sale":0,"stock":3,"unit_type":"Pack","maximum_cart_quantity":3,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"129","position":1}],"module_id":1,"module_type":"groce …[truncated]
```

### GET `api/v1/items/organic`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/organic' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":448,"name":"potato chips","slug":"potato-chips","image_full_url":null,"images_full_url":[null],"price":10,"discount":2,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":0,"unit_type":"Pack","maximum_cart_quantity":0,"veg":0,"organic":1,"is_halal":1,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"4","position":1},{"id":"125","position":2}],"module_id":1,"module_type":"grocery","store_id":1,"store_name":"Organic Shop","store_slug":"organic-shop1","store_image_full_url":"{{host}}\/storage\/app\/pu …[truncated]
```

### GET `api/v1/items/popular`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/popular' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":142,"name":"4X4 Rubiks Cube","slug":"4x4-rubiks-cube142","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-23-623aaee46e10c.png","images_full_url":[],"price":500,"discount":70,"discount_type":"amount","store_discount":0,"flash_sale":0,"stock":39,"unit_type":"Pcs","maximum_cart_quantity":2,"veg":0,"organic":0,"is_halal":1,"avg_rating":4.5,"rating_count":2,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"10","position":1}],"module_id":1,"module_type":"grocery","store_id":34,"store_name":"Country Fair","store_slug":"country-fair34 …[truncated]
```

### GET `api/v1/items/rating/{item_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/rating/101' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"rating":4.33},"errors":[]}
```

### GET `api/v1/items/recently-viewed`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/recently-viewed' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":142,"name":"4X4 Rubiks Cube","slug":"4x4-rubiks-cube142","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-23-623aaee46e10c.png","images_full_url":[],"price":500,"discount":70,"discount_type":"amount","store_discount":0,"flash_sale":0,"stock":39,"unit_type":"Pcs","maximum_cart_quantity":2,"veg":0,"organic":0,"is_halal":1,"avg_rating":4.5,"rating_count":2,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"10","position":1}],"module_id":1,"module_type":"grocery","store_id":34,"store_name":"Country Fair","store_slug":"country-fair34 …[truncated]
```

### GET `api/v1/items/recommended`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/recommended' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/items/related-items/{item_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/related-items/101' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":147,"name":"Tones Mild Chili Powder","slug":"tones-mild-chili-powder147","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-23-623ab56a03afc.png","images_full_url":[],"price":100,"discount":30,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":3993,"unit_type":"Pcs","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"11","position":1}],"module_id":1,"module_type":"grocery","store_id":34,"store_name":"Country Fair","store_slug …[truncated]
```

### GET `api/v1/items/related-store-items/{item_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/related-store-items/101' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":106,"name":"Blue Grapes","slug":"blue-grapes106","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d029d1dc8.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d029d09a9.png"],"price":200,"discount":0,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":927,"unit_type":"Kg","maximum_cart_quantity":0,"veg":0,"organic":1,"is_halal":1,"avg_rating":5,"rating_count":1,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"9","position":1},{"id":"47","position":2}],"module_id":1,"module_t …[truncated]
```

### POST `api/v1/items/reviews/submit`

- **Auth:** `customer`
- **Parameters:** `item_id` (**required**), `order_id` (**required**), `rating` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/items/reviews/submit' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"item_id":5,"order_id":100001,"rating":"test"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The rating must be a number.","content":null,"errors":{"rating":["The rating must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/items/reviews/{item_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/reviews/101' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"rating_summary":{"avg_rating":4,"total_reviews":2,"breakdown":[{"label":"excellent","star":5,"count":1},{"label":"good","star":4,"count":0},{"label":"average","star":3,"count":1},{"label":"below","star":2,"count":0},{"label":"poor","star":1,"count":0}]},"data":[{"id":9,"comment":"Cbbxbx hdhdhd hdhdhd dhdhdh hdhdhd hdhddhud dhdhhd dhdhdh dhfhdhjd fhfhdhr fhdhdhrd hdhdhd dhhdhdrh hdhdhdhd hdhdhdhd hdhdhdhd hdhdhdhdhd dhdhdhrhd X ehdhhdhdbd hdhdhddhhd","rating":5,"attachment":[],"reply":null,"created_at":"2025-11-06T12:59:58.000000Z","customer":{"id":188,"f_name":"Test","l_name":"","image_full_url":null}},{"id":23,"com …[truncated]
```

### GET `api/v1/items/search`

- **Auth:** `public`
- **Parameters:** `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/search?name=Ferrero' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":101,"name":"Ferrero Rocher Chocolate Box","slug":null,"image_full_url":null,"images_full_url":[null],"price":390,"discount":45,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1879,"unit_type":"Pack","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":4,"rating_count":3,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null,"category_ids":[{"id":"11","position":1}],"module_id":1,"module_type":"grocery","store_id":3,"store_name":"Eorange","store_slug":"eorange3","store_image_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27- …[truncated]
```

### GET `api/v1/items/search-suggestion`

- **Auth:** `public`
- **Parameters:** `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/search-suggestion?name=Ferrero' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"name":"Ferrero Rocher Chocolate Box","image":"2022-03-22-6239ceff780fd.png","unit_type":"Pack","image_full_url":null,"images_full_url":[],"video_full_url":null,"video_size":0,"video_preview_type":null,"video_embed_url":null,"video_preview_url":null,"video_thumbnail_url":"{{host}}\/public\/assets\/admin\/img\/video-placeholder.svg","video_preview_modal_type":null,"video_preview_modal_url":null,"has_video_preview":false,"has_video_source":false,"store_category":null,"storage":[],"unit":{"id":4,"unit":"Pack","created_at":"2022-03-22T19:27:18.000000Z","updated_at":"2022-03-22T19:27:18.000000Z","translations":[] …[truncated]
```

### GET `api/v1/items/set-menu`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/set-menu' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"product-001","message":"Set menu not found!"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/items/suggested`

- **Auth:** `public`
- **Parameters:** `store_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/suggested?store_id=3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":101,"name":"Ferrero Rocher Chocolate Box","slug":null,"image_full_url":null,"images_full_url":[null],"price":390,"discount":45,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1879,"unit_type":"Pack","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":4,"rating_count":3,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null,"category_ids":[{"id":"11","position":1}],"module_id":1,"module_type":"grocery","store_id":3,"store_name":"Eorange","store_slug":"eorange3","store_image_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27- …[truncated]
```

### GET `api/v1/items/top-rated`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/items/top-rated' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":57,"name":"Shanghai Bok Choy","slug":"shanghai-bok-choy57","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-10-27-671df6ea1ca72.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671df6ea1bbf6.png"],"price":2.48,"discount":0,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":82,"unit_type":"Kg","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":5,"rating_count":3,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null,"category_ids":[{"id":"12","position":1},{"id":"104","position":2}],"module_id" …[truncated]
```

### GET `api/v1/module`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/module' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":2,"module_name":"Pharmacy_module _pro","module_type":"pharmacy","slug":"pharmacy","short_description":"Fresh, daily & trusted essentials","icon_full_url":"{{host}}\/storage\/app\/public\/module\/2026-06-10-6a28dd97046ec.webp","thumbnail_full_url":"{{host}}\/storage\/app\/public\/module\/2026-06-10-6a28dd9705230.webp","stores_count":17,"min_delivery_time":"7-9 minute","flash_sale":0,"free_delivery":1,"top_offer":{"discount":50,"discount_type":"percent"}},{"id":1,"module_name":"Grocery","module_type":"grocery","slug":"grocery","short_description":"Order from 5,000+ restaurants","icon_full_url":"{{host}}\/ …[truncated]
```

### GET `api/v1/module/top-offer`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/module/top-offer' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"discount":90,"discount_type":"percent"},"errors":[]}
```

### GET `api/v1/most-tips`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/most-tips' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"most_tips_amount":15},"errors":[]}
```

### POST `api/v1/newsletter/subscribe`

- **Auth:** `public`
- **Parameters:** `email` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/newsletter/subscribe' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"email":"6amtech@gmail.com"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The email has already been taken.","content":null,"errors":{"email":["The email has already been taken."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/offers/items`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/offers/items' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":133,"name":"Mazola Corn Oil","slug":"mazola-corn-oil133","image_full_url":null,"images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671e29fb2b1fb.png",null],"price":200,"discount":90,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":586,"unit_type":"Ltr","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"102","position":1},{"id":"140","position":2}],"module_id":1,"module_type":"grocery","store_id":5,"store_name":"Family  …[truncated]
```

### GET `api/v1/offers/stores`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/offers/stores' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":14,"name":"Smart Shopping","slug":"smart-shopping14","logo_full_url":null,"cover_photo_full_url":null,"module_id":1,"module_type":"grocery","avg_rating":5,"reviews_count":3,"items_count":0,"category_ids":[62,10,114,8,109,11,108],"category_names":["Chicken","Cookies","Butter","Eggs"],"delivery_time":"2-3 hours","min_delivery_time":2,"max_delivery_time":3,"distance":24740.379145035757,"distance_km":24.74,"open":1,"current_opening_time":"00:00:00","active":1,"free_delivery":0,"is_new":0,"ad":0,"avg_item_discount_percentage":31.25,"store_discount":{"discount":10,"discount_type":"percent"},"offers":[{"type": …[truncated]
```

### GET `api/v1/offline_payment_method_list`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/offline_payment_method_list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":3,"method_name":"Bkash","method_fields":[{"input_name":"account_number","input_data":"<REDACTED>"},{"input_name":"routing_number","input_data":"234123412fasdfasdfasdfasdfasdfasdfasdfasdfas"},{"input_name":"branch","input_data":"Dhaka"},{"input_name":"bank_name","input_data":"Dhaka Bank"}],"method_informations":[{"customer_input":"branch_name","customer_placeholder":"Branch Name","is_required":1},{"customer_input":"additional__info","customer_placeholder":"Additional Info","is_required":0}]},{"id":4,"method_name":"xcfvz","method_fields":[{"input_name":"asdfas","input_data":"23412"},{"input_name":"asdfasd …[truncated]
```

### GET `api/v1/other-banners`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/other-banners' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"bottom_section_banner_full_url":"{{host}}\/storage\/app\/public\/promotional_banner\/2026-06-14-6a2e2d8a77e00.webp"},"errors":[]}
```

### GET `api/v1/other-banners/video-content`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/other-banners/video-content' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"banner_contents":[],"banner_type":null,"banner_video":null,"banner_image_full_url":null,"banner_video_content_full_url":null},"errors":[]}
```

### GET `api/v1/other-banners/why-choose`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/other-banners/why-choose' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/parcel-category`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/parcel-category' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 5'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":2,"name":"Gifts","description":"Send heartfelt presents, right on time","image_full_url":"{{host}}\/storage\/app\/public\/parcel_category\/2026-06-17-6a321682cb892.webp","parcel_per_km_shipping_charge":100,"parcel_minimum_shipping_charge":40},{"id":3,"name":"Documents","description":"From IDs to forms, we deliver it all","image_full_url":"{{host}}\/storage\/app\/public\/parcel_category\/2026-06-17-6a32160318157.webp","parcel_per_km_shipping_charge":5,"parcel_minimum_shipping_charge":50},{"id":4,"name":"Electronics","description":"Safeguard your gadgets with secure delivery","image_full_url":"{{host}}\/s …[truncated]
```

### GET `api/v1/privacy-policy`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/privacy-policy' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":"<h2>This is a Demo Privacy Policy<\/h2>\r\n\r\n<p>This policy explains how 6amMart&nbsp;website and related applications (the &ldquo;Site&rdquo;, &ldquo;we&rdquo; or &ldquo;us&rdquo;) collects, uses, shares and protects the personal information that we collect through this site or different channels. 6amMart has established the site to link up the users who need foods or grocery items to be shipped or delivered by the riders from the affiliated restaurants or shops to the desired location. This policy also applies to any mobile applications that we develop for use with our services on the Site, and references to this …[truncated]
```

### GET `api/v1/pro-customer/faqs`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/pro-customer/faqs' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"question":"dfsadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasdf sadfasdfsadfa sdfsadfasdfsa dfasd","answer":"dfgsadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasdf sadfasdfsadfa sdfsadfasdfsa dfasdfs adfasdfssadfasd …[truncated]
```

### GET `api/v1/pro-customer/plans`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/pro-customer/plans' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"pro_member_status":1,"pro_brand":"6amMartt Pro","plans":[{"id":4,"plan_name":"Elite Pro Trial","plan_type":"free_trial","price":0,"duration":1,"duration_label":"1 Days","status":1},{"id":9,"plan_name":"Best","plan_type":"paid","price":11.99,"duration":10,"duration_label":"10 Days","status":1},{"id":8,"plan_name":"Pro 01","plan_type":"paid","price":23,"duration":15,"duration_label":"15 Days","status":1},{"id":6,"plan_name":"pro 002","plan_type":"paid","price":200,"duration":20,"duration_label":"20 Days","status":1},{"id":10,"plan_name":"12341234","plan_type":"paid","price":123,"duration":123,"duration_label":"123 Day …[truncated]
```

### GET `api/v1/pro-customer/terms-and-conditions`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/pro-customer/terms-and-conditions' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"page_status":1,"page_title":"asdfa asdfas asdfas asdfas asdfasd asfa sdf asdfasd asdfasd asf asdf asf\u00a0 asdf asfd asdfa asd fasdas","page_description":"<p>asdfas asdfas asdfas asdfasd asfa sdf asdfasd asdfasd asf asdf asf&nbsp; asdf asfd asdfa asd fasd&nbsp;&nbsp;asdfas asdfas asdfas asdfasd asfa sdf asdfasd asdfasd asf asdf asf&nbsp; asdf asfd asdfa asd fasdasdfas asdfas asdfas asdfasd asfa sdf asdfasd asdfasd asf asdf asf&nbsp; asdf asfd asdfa asd fasdasdfas asdfas asdfas asdfasd asfa sdf asdfasd asdfasd asf asdf asf&nbsp; asdf asfd asdfa asd fasdasdfas asdfas asdfas asdfasd asfa sdf asdfasd asdfasd asf asdf a …[truncated]
```

### GET `api/v1/react-landing-page`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/react-landing-page' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"hero_section":{"header_title":"Your Everyday $Needs$, Delivered Fast","header_sub_title":"Select your favorite module and enjoy fast delivery of groceries, food, medicine, parcels, and more from your favorite s","header_tag_line":"Select a module and enjoy your next order!","pick_location_title":"Discover everything you need near you tyuryt 65u7"},"trust_section":{"trust_section_status":1,"cards":[{"status":1,"title":"10,000+10,000+10,000","sub_title":"Orders Delivered","image_full_url":null},{"status":1,"title":"1200+","sub_title":"Happy Customers","image_full_url":null},{"status":1,"title":"2434+","sub_title":"Act …[truncated]
```

### GET `api/v1/refund-policy`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/refund-policy' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":"<p>6amMart is a complete Multi-vendor Food, Grocery, eCommerce, Parcel, Pharmacy, or any kind of products delivery system developed with powerful admin panel will help you to control your business smartly.<\/p>\r\n\r\n<p>Praesent fermentum finibus lacus. Nulla tincidunt lectus sed purus facilisis hendrerit. Maecenas volutpat elementum orci, tincidunt euismod ante facilisis ac. Integer dignissim iaculis varius. Mauris iaculis elit vel posuere pellentesque. Praesent a mi sed neque ullamcorper dignissim sed ut nibh. Sed purus dui, sodales in varius in, accumsan at libero. Vestibulum posuere dui et orci tincidunt, ac con …[truncated]
```

### GET `api/v1/rental/banners`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/banners' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"banners":[{"type":"store_wise","link":null,"provider_id":60,"image_full_url":null},{"type":"default","link":"https:\/\/codecanyon.net\/item\/<REDACTED>\/36772112?s_rank=16","provider_id":null,"image_full_url":"{{host}}\/storage\/app\/public\/banner\/2025-02-08-67a6ccaa19cdc.png"},{"type":"default","link":"https:\/\/codecanyon.net\/item\/<REDACTED>\/36772112?s_rank=16","provider_id":null,"image_full_url":"{{host}}\/storage\/app\/public\/banner\/2026-06-18-6a33b8707be4b.webp"},{"type":"store_wise","link":null,"provider_id":60,"image_full_url":"{{host}}\/storage\/app\/public\/banner\/2026-06-18-6a33b87f938db.webp"},{"t …[truncated]
```

### GET `api/v1/rental/banners/{store_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/banners/60' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/coupon/apply`

- **Auth:** `customer`
- **Parameters:** `code` (**required**), `provider_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/coupon/apply?code=bogo&provider_id=60' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"coupon","message":"Coupon not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/coupon/list`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/coupon/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"title":"Save 15% on Your First Ride \u2013 Book Now!","code":"FirstTrip15","start_date":"2025-02-05","expire_date":"2029-08-30","min_purchase":100,"max_discount":1000,"discount":15,"discount_type":"percent","coupon_type":"first_order","data":"\"\"","store_id":null,"store":null},{"title":"Limited Time Offer: 20% Off on All Rentals!","code":"Limited20","start_date":"2025-02-05","expire_date":"2029-12-05","min_purchase":100,"max_discount":1000,"discount":20,"discount_type":"percent","coupon_type":"default","data":"\"\"","store_id":null,"store":null},{"title":"Weekend Special: 30% Off All Bookings!","code":"Wee …[truncated]
```

### GET `api/v1/rental/coupon/list/all`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/coupon/list/all' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"title":"Save 15% on Your First Ride \u2013 Book Now!","code":"FirstTrip15","start_date":"2025-02-05","expire_date":"2029-08-30","min_purchase":100,"max_discount":1000,"discount":15,"discount_type":"percent","coupon_type":"first_order","data":"\"\"","store_id":null,"store":null},{"title":"Get 10% Off on Your Next Taxi Rental!","code":"Trip10","start_date":"2025-02-05","expire_date":"2029-12-21","min_purchase":100,"max_discount":1000,"discount":10,"discount_type":"percent","coupon_type":"default","data":"\"\"","store_id":null,"store":null},{"title":"Limited Time Offer: 20% Off on All Rentals!","code":"Limited …[truncated]
```

### GET `api/v1/rental/customer/trip/last`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/customer/trip/last' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[],"errors":[]}
```

### GET `api/v1/rental/provider/get-provider-details/{provider}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/provider/get-provider-details/60' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":60,"name":"CityRide Rentals","phone":"+1 959-252-4064","email":"provider1@demo.com","logo":"2025-02-05-67a33b277371b.png","latitude":"24.88400610940222","longitude":"83.92862451465382","address":"Andhra Pradesh","footer_text":null,"minimum_order":0,"comission":10,"schedule_order":true,"status":1,"vendor_id":60,"created_at":"2025-02-05T16:19:19.000000Z","updated_at":"2026-06-21T12:27:17.000000Z","free_delivery":false,"cover_photo":"2025-02-05-67a33b2775cdd.png","delivery":true,"take_away":true,"item_section":true,"tax":66,"zone_id":1,"reviews_section":true,"active":true,"off_day":" ","self_delivery_system":1,"pos …[truncated]
```

### GET `api/v1/rental/provider/get-provider-reviews/{provider}`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/provider/get-provider-reviews/60?limit=10&offset=1&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"provider":{"name":"CityRide Rentals","ratings":[3,2,1,0,0],"avg_rating":4.33,"rating_count":6},"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/provider/latest`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/provider/latest' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":138,"name":"Ciara David","address":"Aut tenetur cum reru","logo_full_url":null,"cover_photo_full_url":null,"delivery_time":"21-13 hours","distance":6387030.137536694,"vehicles_count":1,"verified_seller":1,"ad":0,"discount":null},{"id":134,"name":"Tets","address":"10 Rd 35, Dhaka 1212, Bangladesh","logo_full_url":null,"cover_photo_full_url":null,"delivery_time":"11-11 minute","distance":6526.110275880673,"vehicles_count":0,"verified_seller":0,"ad":0,"discount":null},{"id":114,"name":"Tets","address":"C. de los Laureles 68, Tesistan, 45200 Tesist\u00e1n, Jal., Mexico","logo_full_url":null,"cover_photo_ful …[truncated]
```

### GET `api/v1/rental/provider/popular`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/provider/popular' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":66,"name":"RideMaster Taxis","address":"London, UK","logo_full_url":null,"cover_photo_full_url":null,"delivery_time":"10-30 min","distance":64661.90427052711,"vehicles_count":10,"verified_seller":1,"ad":0,"discount":null},{"id":60,"name":"CityRide Rentals","address":"Andhra Pradesh","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2025-02-05-67a33b277371b.png","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2025-02-05-67a33b2775cdd.png","delivery_time":"20-50 min","distance":670579.309823035,"vehicles_count":1,"verified_seller":1,"ad":0,"discount":null},{"id":65,"name":"Urba …[truncated]
```

### GET `api/v1/rental/provider/verified`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/provider/verified' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":66,"name":"RideMaster Taxis","address":"London, UK","logo_full_url":null,"cover_photo_full_url":null,"delivery_time":"10-30 min","distance":64661.90427052711,"vehicles_count":10,"verified_seller":1,"ad":0,"discount":null},{"id":60,"name":"CityRide Rentals","address":"Andhra Pradesh","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2025-02-05-67a33b277371b.png","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2025-02-05-67a33b2775cdd.png","delivery_time":"20-50 min","distance":670579.309823035,"vehicles_count":1,"verified_seller":1,"ad":0,"discount":null},{"id":138,"name":"Cia …[truncated]
```

### POST `api/v1/rental/user/cart/add-to-cart`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `vehicle_id` (**required**), `reel_id` (optional), `rental_type` (**required**), `estimated_hours` (conditional — `required_if:rental_type,hourly`), `distance` (conditional — `required_if:rental_type,distance_wise`), `destination_time` (conditional — `required_if:rental_type,distance_wise`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/user/cart/add-to-cart' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","vehicle_id":1,"reel_id":2,"rental_type":"hourly","estimated_hours":"test","distance":1,"destination_time":"09:00"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"cart_item","message":"Vehicle currently unavailable!"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/rental/user/cart/get-cart`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/user/cart/get-cart?guest_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"carts":[{"id":968,"provider_id":66,"user_id":8,"vehicle_id":20,"reel_id":null,"module_id":6,"quantity":1,"is_guest":0,"price":-50,"created_at":"2026-08-27T08:12:53.000000Z","updated_at":"2026-08-27T08:13:18.000000Z","vehicle":{"id":20,"name":"Zachery Newton","description":"Adipisci magna susci","thumbnail":"2025-06-01-683bd564e15fa.png","images":"[{\"img\":\"2025-06-01-683bd564e4015.png\",\"storage\":\"public\"}]","zone_id":1,"provider_id":66,"brand_id":7,"category_id":2,"model":"798","type":"full_size","engine_capacity":"832","engine_power":"524","seating_capacity":"479","air_condition":1,"fuel_type":"petrol","tran …[truncated]
```

### DELETE `api/v1/rental/user/cart/remove-cart`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/user/cart/remove-cart' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"carts":[],"user_data":[],"status":"success"},"errors":[]}
```

### DELETE `api/v1/rental/user/cart/remove-multiple-cart`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `cart_ids` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/user/cart/remove-multiple-cart' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","cart_ids":[7067]}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"carts":[],"user_data":{"user_id":8,"is_guest":0,"pickup_location":null,"destination_location":null,"pickup_time":"2026-08-27T08:13:54.656195Z","rental_type":"hourly","estimated_hours":0,"distance":0,"destination_time":0,"total_cart_price":0,"updated_at":"2026-08-27T08:13:54.000000Z","created_at":"2026-08-27T08:13:54.000000Z","id":550}},"errors":[]}
```

### DELETE `api/v1/rental/user/cart/remove-vehicle/{cart_id}`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/user/cart/remove-vehicle/968' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"carts":[],"user_data":{"id":550,"user_id":8,"pickup_location":null,"destination_location":null,"pickup_time":"2026-08-27 14:13:54","rental_type":"hourly","estimated_hours":0,"distance":0,"total_cart_price":0,"destination_time":0,"is_guest":0,"created_at":"2026-08-27T08:13:54.000000Z","updated_at":"2026-08-27T08:13:54.000000Z"}},"errors":[]}
```

### PUT `api/v1/rental/user/cart/update-cart`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `cart_id` (**required**), `quantity` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/rental/user/cart/update-cart' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","cart_id":7067,"quantity":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"cart","message":"Cart not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### PUT `api/v1/rental/user/cart/update-user-data/{user_data}`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `rental_type` (**required**), `estimated_hours` (conditional — `required_if:rental_type,hourly`), `distance` (conditional — `required_if:rental_type,distance_wise`), `destination_time` (conditional — `required_if:rental_type,distance_wise`)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/rental/user/cart/update-user-data/50' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","rental_type":"hourly","estimated_hours":"test","distance":1,"destination_time":"09:00"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"carts":[{"id":968,"provider_id":66,"user_id":8,"vehicle_id":20,"reel_id":null,"module_id":6,"quantity":1,"is_guest":0,"price":-50,"created_at":"2026-08-27T08:12:53.000000Z","updated_at":"2026-08-27T08:13:18.000000Z","vehicle":{"id":20,"name":"Zachery Newton","description":"Adipisci magna susci","thumbnail":"2025-06-01-683bd564e15fa.png","images":"[{\"img\":\"2025-06-01-683bd564e4015.png\",\"storage\":\"public\"}]","zone_id":1,"provider_id":66,"brand_id":7,"category_id":2,"model":"798","type":"full_size","engine_capacity":"832","engine_power":"524","seating_capacity":"479","air_condition":1,"fuel_type":"petrol","tran …[truncated]
```

### POST `api/v1/rental/user/review/add`

- **Auth:** `customer`
- **Parameters:** `vehicle_id` (**required**), `trip_id` (**required**), `vehicle_identity_id` (**required**), `rating` (**required**), `comment` (optional), `attachment` (optional), `attachment.*` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/user/review/add' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"vehicle_id":1,"trip_id":100000,"vehicle_identity_id":1,"rating":"test","comment":"test","attachment":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The rating must be a number.","content":null,"errors":{"rating":["The rating must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/rental/user/trip/cancel-trip`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `trip_id` (**required**), `cancellation_reason` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/rental/user/trip/cancel-trip' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","trip_id":100037,"cancellation_reason":"test"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"trip","message":"Trip data not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### DELETE `api/v1/rental/user/trip/delete-trip`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `trip_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/user/trip/delete-trip' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","trip_id":100037}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":null,"errors":[]}
```

### POST `api/v1/rental/user/trip/get-tax`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/user/trip/get-tax' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"provider","message":"Provider not found"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/rental/user/trip/get-trip-details`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `trip_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/user/trip/get-trip-details?guest_id=1&trip_id=100037' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"trip","message":"Trip data not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/user/trip/get-trip-list/{all}`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `limit` (optional), `offset` (optional), `trip_status` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/user/trip/get-trip-list/all?guest_id=1&limit=10&offset=1&trip_status=pending' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":100245,"trip_amount":7345,"discount_on_trip":50,"coupon_discount_amount":0,"pro_discount":60,"trip_status":"pending","payment_status":"unpaid","tax_amount":2445,"tax_status":"excluded","tax_percentage":0,"trip_type":"day_wise","additional_charge":10,"distance":0.034,"estimated_hours":120,"pickup_location":{"lat":"23.8373932","lng":"90.3758327","location_name":"1005 Avenue 11, Dhaka, Bangladesh","location_type":null},"destination_location":{"lat":"23.83756096372672","lng":"90.37580832839012","location_name":"R9PG+XCH, Dhaka, Bangladesh","location_type":null},"trip_note":null,"schedule_at":"2026-07-08 16: …[truncated]
```

### POST `api/v1/rental/user/trip/payment`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `trip_id` (**required**), `payment_method` (**required**), `payment_gateway` (conditional — `required_if:payment_method,digital_payment,partial_payment`), `callback_url` (conditional — `required_if:payment_method,digital_payment`), `payment_platform` (conditional — `required_if:payment_method,digital_payment`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/user/trip/payment' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","trip_id":100037,"payment_method":"cash_payment","payment_gateway":"test","callback_url":"test","payment_platform":"test"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"trip","message":"Trip data not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/rental/user/trip/reorder`

- **Auth:** `customer`
- **Parameters:** `trip_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/user/trip/reorder' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"trip_id":100037}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"cart_count":0,"added_count":0,"skipped_count":1,"unavailable_items":[{"id":1,"name":"Toyota Corolla","code":"vehicle_not_found","message":"Toyota Corolla Is not available"}],"skipped_items":[],"message":"Items added to cart"},"errors":[]}
```

### POST `api/v1/rental/user/trip/trip-booking`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `trip_amount` (**required**), `trip_type` (**required**), `provider_id` (**required**), `contact_person_name` (**required**), `contact_person_number` (**required**), `contact_person_email` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/user/trip/trip-booking' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","trip_amount":100,"trip_type":"hourly","provider_id":60,"contact_person_name":"test","contact_person_number":"+8801700000000","contact_person_email":"6amtech@gmail.com"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"cart","message":"Your cart is empty"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/rental/user/wish-list`

- **Auth:** `customer`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/user/wish-list?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"providers":[{"id":61,"name":"SwiftMove Taxis","phone":"+8801655443322","email":"provider2@demo.com","logo":"2025-02-05-67a33c5d8b2dc.png","latitude":"22.680279740759556","longitude":"81.00374585791369","address":"Arunachal Pradesh.","footer_text":null,"minimum_order":0,"comission":null,"schedule_order":false,"status":1,"vendor_id":61,"created_at":"2025-02-05T16:24:29.000000Z","updated_at":"2025-12-11T14:46:09.000000Z","free_delivery":false,"cover_photo":"2025-02-05-67a33c5d8d894.png","delivery":true,"take_away":true,"item_section":true,"tax":5,"zone_id":1,"reviews_section":true,"active":true,"off_day":" ","self_deli …[truncated]
```

### POST `api/v1/rental/user/wish-list/add`

- **Auth:** `customer`
- **Parameters:** `vehicle_id` (conditional — `required_without:provider_id`), `provider_id` (conditional — `required_without:vehicle_id`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/user/wish-list/add' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"vehicle_id":1,"provider_id":60}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"data","message":"Cannot add both vehicle and Provider at same time"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/rental/user/wish-list/remove`

- **Auth:** `customer`
- **Parameters:** `vehicle_id` (conditional — `required_without:provider_id`), `provider_id` (conditional — `required_without:vehicle_id`)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/user/wish-list/remove' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"vehicle_id":1,"provider_id":60}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"wishlist","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/vehicle/brand-list`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vehicle/brand-list?limit=10&offset=1&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/vehicle/category-list`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vehicle/category-list?limit=10&offset=1&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/vehicle/get-provider-vehicles`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `sortby_price` (optional), `trip_type` (optional), `provider_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vehicle/get-provider-vehicles?limit=10&offset=1&sortby_price=asc&trip_type=hourly&provider_id=60' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":43,"name":"Toyota Corolla","slug":"toyota-corolla","description":"Daily Commuting (Economical and Efficient)","provider_id":60,"type":"compact","engine_capacity":"1000","seating_capacity":"4","air_condition":1,"fuel_type":"octan","transmission_type":"automatic","trip_hourly":1,"trip_distance":1,"trip_day_wise":0,"day_wise_price":0,"hourly_price":250,"distance_price":500,"discount_type":"percent","discount_price":10,"status":1,"new_tag":1,"avg_rating":4,"total_reviews":1,"thumbnail_full_url":null,"images_full_url":["{{host}}\/storage\/app\/public\/vehicle\/2025-02-05-67a34d27c9a81.png"],"total_vehicle_co …[truncated]
```

### GET `api/v1/rental/vehicle/get-vehicle-details/{vehicle}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vehicle/get-vehicle-details/43' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":43,"name":"Toyota Corolla","slug":"toyota-corolla","description":"Daily Commuting (Economical and Efficient)","provider_id":60,"type":"compact","engine_capacity":"1000","seating_capacity":"4","air_condition":1,"fuel_type":"octan","transmission_type":"automatic","trip_hourly":1,"trip_distance":1,"trip_day_wise":0,"day_wise_price":0,"hourly_price":250,"distance_price":500,"discount_type":"percent","discount_price":10,"status":1,"new_tag":1,"avg_rating":4,"total_reviews":1,"thumbnail_full_url":null,"images_full_url":["{{host}}\/storage\/app\/public\/vehicle\/2025-02-05-67a34d27c9a81.png"],"verified_seller":1,"provi …[truncated]
```

### GET `api/v1/rental/vehicle/popular-suggestion`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vehicle/popular-suggestion?name=Toyota' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[{"id":5,"name":"Audi","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2025-02-05-67a330f2f0ea5.png"},{"id":11,"name":"Land Rover","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2025-02-05-67a3317f1ba89.png"},{"id":8,"name":"Nissan","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2025-02-05-67a3313cb2997.png"},{"id":7,"name":"Chevrolet","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2025-02-05-67a331261c331.png"},{"id":1,"name":"Toyota","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2025-02-05-67a3306896559.png"},{"id":10,"name":"Tesla","image_full_url":"{{host}}\/storag …[truncated]
```

### GET `api/v1/rental/vehicle/reviews/{id}`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vehicle/reviews/43?limit=10&offset=1&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/vehicle/search`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `sortby_price` (optional), `trip_type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vehicle/search?limit=10&offset=1&sortby_price=asc&trip_type=hourly&name=Toyota' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":43,"name":"Toyota Corolla","slug":"toyota-corolla","description":"Daily Commuting (Economical and Efficient)","provider_id":60,"type":"compact","engine_capacity":"1000","seating_capacity":"4","air_condition":1,"fuel_type":"octan","transmission_type":"automatic","trip_hourly":1,"trip_distance":1,"trip_day_wise":0,"day_wise_price":0,"hourly_price":250,"distance_price":500,"discount_type":"percent","discount_price":10,"status":1,"new_tag":1,"avg_rating":4,"total_reviews":1,"thumbnail_full_url":null,"images_full_url":["{{host}}\/storage\/app\/public\/vehicle\/2025-02-05-67a34d27c9a81.png"],"total_vehicle_co …[truncated]
```

### GET `api/v1/rental/vehicle/search/suggestion`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `sortby_price` (optional), `trip_type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vehicle/search/suggestion?limit=10&offset=1&sortby_price=asc&trip_type=hourly&name=Toyota' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":["Toyota - Toyota Corolla","Toyota - Veda Albert"],"errors":[]}
```

### GET `api/v1/rental/vehicle/top-rated`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `sortby_price` (optional), `trip_type` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vehicle/top-rated?limit=10&offset=1&sortby_price=asc&trip_type=hourly' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":22,"name":"Text Bmw","slug":"text-bmw","description":"Dhdhhddh","provider_id":66,"type":"executives","engine_capacity":"22","seating_capacity":"55","air_condition":1,"fuel_type":"jet_fuel","transmission_type":"dual_clutch","trip_hourly":1,"trip_distance":1,"trip_day_wise":1,"day_wise_price":1000,"hourly_price":100,"distance_price":50,"discount_type":"amount","discount_price":50,"status":1,"new_tag":1,"avg_rating":5,"total_reviews":1,"thumbnail_full_url":null,"images_full_url":[null],"total_vehicle_count":2,"verified_seller":1,"provider":{"id":66,"name":"RideMaster Taxis","address":"London, UK","tax":20, …[truncated]
```

### POST `api/v1/rental/vendor/banner/create`

- **Auth:** `vendor`
- **Parameters:** `image` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/banner/create' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Image is required","content":null,"errors":{"image":["Image is required"],"translations":["Title and description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### DELETE `api/v1/rental/vendor/banner/delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/vendor/banner/delete/7' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Banner not found.","content":null,"errors":[{"code":"not_found","message":"Banner not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/vendor/banner/edit/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/banner/edit/7' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Banner not found.","content":null,"errors":[{"code":"not_found","message":"Banner not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/vendor/banner/featured/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/banner/featured/7' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Banner not found.","content":null,"errors":[{"code":"not_found","message":"Banner not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/vendor/banner/list`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/banner/list?limit=10&offset=1&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/vendor/banner/status/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/banner/status/7' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Banner not found.","content":null,"errors":[{"code":"not_found","message":"Banner not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/rental/vendor/banner/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `image` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/banner/update/7' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Title and description in english is required","content":null,"errors":{"translations":["Title and description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### GET `api/v1/rental/vendor/brand/list`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/brand/list?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":15,"name":"Fresh Flavor Dhaka Essentials","image_full_url":null,"status":1},{"id":14,"name":"Brand Cat","image_full_url":null,"status":1},{"id":13,"name":"Brand cat","image_full_url":null,"status":1},{"id":12,"name":"Porsche","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2025-02-05-67a3319a12feb.png","status":1},{"id":11,"name":"Land Rover","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2025-02-05-67a3317f1ba89.png","status":1},{"id":10,"name":"Tesla","image_full_url":"{{host}}\/storage\/app\/public\/brand\/2025-02-05-67a331679c222.png","status":1},{"id":9,"name":"Hyundai","image_fu …[truncated]
```

### GET `api/v1/rental/vendor/category/list`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/category/list?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":12,"name":"Cat rent","image_full_url":null,"status":1},{"id":11,"name":"Luxury Minibus","image_full_url":"{{host}}\/storage\/app\/public\/category\/2025-02-05-67a3301d4e52d.png","status":1},{"id":10,"name":"Crossover","image_full_url":"{{host}}\/storage\/app\/public\/category\/2025-02-05-67a32ffce3535.png","status":1},{"id":9,"name":"Limousine","image_full_url":"{{host}}\/storage\/app\/public\/category\/2025-02-05-67a32fe3e07b8.png","status":1},{"id":8,"name":"Family Van","image_full_url":"{{host}}\/storage\/app\/public\/category\/2025-02-05-67a32fc64426e.png","status":1},{"id":7,"name":"Electric Car"," …[truncated]
```

### POST `api/v1/rental/vendor/coupon/create`

- **Auth:** `vendor`
- **Parameters:** `code` (**required**), `start_date` (**required**), `expire_date` (**required**), `coupon_type` (**required**), `discount` (conditional — `required_if:coupon_type,default`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/coupon/create' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"code":"bogo","start_date":"2026-08-27","expire_date":"2026-08-27","coupon_type":"free_delivery","discount":1}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The code has already been taken.","content":null,"errors":{"code":["The code has already been taken."],"translations":["Title in English is required"]}}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/rental/vendor/coupon/delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/vendor/coupon/delete/461' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Coupon not found.","content":null,"errors":[{"code":"not_found","message":"Coupon not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/vendor/coupon/edit/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/coupon/edit/461' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Coupon not found.","content":null,"errors":[{"code":"not_found","message":"Coupon not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/vendor/coupon/list`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/coupon/list?limit=10&offset=1&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/vendor/coupon/status/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/coupon/status/461' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Coupon not found.","content":null,"errors":[{"code":"not_found","message":"Coupon not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/rental/vendor/coupon/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `code` (**required**), `start_date` (**required**), `expire_date` (**required**), `coupon_type` (**required**), `discount` (conditional — `required_if:coupon_type,default`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/coupon/update/461' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"code":"bogo","start_date":"2026-08-27","expire_date":"2026-08-27","coupon_type":"free_delivery","discount":1}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The code has already been taken.","content":null,"errors":{"code":["The code has already been taken."],"translations":["Title in English is required"]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/rental/vendor/driver/create`

- **Auth:** `vendor`
- **Parameters:** `first_name` (**required**), `last_name` (**required**), `email` (**required**), `phone` (**required**), `identity_type` (**required**), `identity_number` (**required**), `image` (optional), `identity_image` (optional), `identity_image.*` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/driver/create' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"first_name":"Audit","last_name":"Probe","email":"provider1@demo.com","phone":"+101747410000","identity_type":"test","identity_number":"test","identity_image":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Image is required","content":null,"errors":{"image":["Image is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### DELETE `api/v1/rental/vendor/driver/delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/vendor/driver/delete/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"driver","message":"Failed to delete driver."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/vendor/driver/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/driver/details/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"driver","message":"Driver not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/vendor/driver/list`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/driver/list?limit=10&offset=1&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/vendor/driver/status/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/driver/status/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"driver","message":"Driver not found."}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/rental/vendor/driver/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `first_name` (**required**), `last_name` (**required**), `email` (**required**), `phone` (**required**), `identity_type` (**required**), `identity_number` (**required**), `image` (optional), `identity_image` (optional), `identity_image.*` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/driver/update/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"first_name":"Audit","last_name":"Probe","email":"provider1@demo.com","phone":"+101747410000","identity_type":"test","identity_number":"test","identity_image":[]}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"driver","message":"Driver not found."}]}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### GET `api/v1/rental/vendor/get-earning-report`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/get-earning-report' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"summary":{"total_earning":31150.17,"previous_total_earning":0,"total_earning_percentage":100,"total_earning_positive":true,"total_expense":12972.23,"previous_total_expense":0,"total_expense_percentage":100,"total_expense_positive":true,"net_income":18177.94,"previous_net_income":0,"net_income_percentage":100,"net_income_positive":true,"counts":{"earning":20,"expense":39,"subscription":12},"breakdown":{"trip_store_earning":16378.36,"trip_store_earning_percentage":55.21,"tax_amount":13289.08,"tax_amount_percentage":44.79},"trip_commission":1482.73,"trip_commission_percentage":11.43,"vendor_expense_amount":2002.5,"vend …[truncated]
```

### GET `api/v1/rental/vendor/get-tax-report`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional), `from` (**required**), `to` (**required**), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/get-tax-report?limit=10&offset=1&from=2026-08-27&to=2026-08-27&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The from does not match the format m\/d\/Y.","content":null,"errors":{"from":["The from does not match the format m\/d\/Y."],"to":["The to does not match the format m\/d\/Y."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/rental/vendor/message/details`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/message/details' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"status":false,"conversation":null,"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/vendor/message/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/message/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":73,"sender_type":"vendor","receiver_type":"customer","unread_message_count":1,"last_message_time":"2026-08-20 13:40:09","sender":{"id":52,"f_name":"CityRide Rentals","l_name":"","phone":"+1 959-252-4064","image_full_url":"{{host}}\/storage\/app\/public\/store\/2025-02-05-67a33b277371b.png"},"receiver":{"id":16,"f_name":"Audit","l_name":"Probe","phone":"+8801700000000","image_full_url":"{{host}}\/storage\/app\/public\/profile\/2026-07-02-6a45fd3b80ee9.webp"},"last_message":{"sender_id":52,"message":"audit probe","file_full_url":[],"is_seen":0,"created_at":"2026-08-20T07:40:09.000000Z"}}],"pagination":{"c …[truncated]
```

### GET `api/v1/rental/vendor/message/search-list`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/message/search-list?name=Toyota' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### POST `api/v1/rental/vendor/message/send`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/message/send' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Validation failed","content":null,"errors":[{"code":"receiver_id","message":"Receiver not found"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/rental/vendor/profile`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/profile' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":60,"f_name":"Akeem","l_name":"Boyle","phone":"+1 959-252-4064","email":"provider1@demo.com","email_verified_at":null,"created_at":"2025-02-05T16:19:19.000000Z","updated_at":"2026-08-27T08:13:12.000000Z","rejection_note":null,"image":null,"status":1,"firebase_token":"@","login_remember_token":"<REDACTED>","order_count":29,"todays_order_count":0,"this_week_order_count":0,"this_month_order_count":0,"todays_earning":0,"this_week_earning":0,"this_month_earning":0,"member_since_days":567,"cash_in_hands":9373.59,"balance":23800.93,"total_earning":36661.52,"Payable_Balance":0,"withdraw_able_balance":33174.52,"adjust_abl …[truncated]
```

### POST `api/v1/rental/vendor/profile/update`

- **Auth:** `vendor`
- **Parameters:** `f_name` (**required**), `l_name` (**required**), `phone` (**required**), `password` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/profile/update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"f_name":"Audit","l_name":"Probe","phone":"+101747410000","password":"Str0ng@Pass1"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The phone has already been taken.","content":null,"errors":{"phone":["The phone has already been taken."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/rental/vendor/schedule/create`

- **Auth:** `vendor`
- **Parameters:** `opening_time` (**required**), `closing_time` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/schedule/create' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"opening_time":"2026-08-27","closing_time":"2026-08-27"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The opening time does not match the format H:i:s.","content":null,"errors":{"opening_time":["The opening time does not match the format H:i:s."],"closing_time":["The closing time does not match the format H:i:s.","End time must be after the start time"]}}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/rental/vendor/schedule/delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/vendor/schedule/delete/717' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"not-fond","message":"Schedule not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### PUT `api/v1/rental/vendor/trip/assign-driver`

- **Auth:** `vendor`
- **Parameters:** `trip_id` (**required**), `driver_ids` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/rental/vendor/trip/assign-driver' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"trip_id":100031,"driver_ids":[1]}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"trip","message":"Vehicle information not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### PUT `api/v1/rental/vendor/trip/assign-vehicle`

- **Auth:** `vendor`
- **Parameters:** `trip_id` (**required**), `vehicle_identity_ids` (**required**), `trip_details_id` (**required**), `vehicle_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/rental/vendor/trip/assign-vehicle' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"trip_id":100031,"vehicle_identity_ids":[1],"trip_details_id":1,"vehicle_id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"trip","message":"Vehicle not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/rental/vendor/trip/details`

- **Auth:** `vendor`
- **Parameters:** `trip_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/trip/details?trip_id=100031' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":100031,"user_id":28,"provider_id":60,"zone_id":1,"module_id":6,"pickup_zone_id":1,"cash_back_id":24,"trip_amount":180.6,"discount_on_trip":18.96,"discount_on_trip_by":"vendor","coupon_discount_amount":0,"coupon_discount_by":"none","coupon_code":null,"trip_status":"completed","payment_status":"paid","payment_method":"cash_on_delivery","transaction_reference":"test","tax_amount":67.82891566,"tax_status":"included","tax_percentage":66,"trip_type":"distance_wise","additional_charge":10,"partially_paid_amount":0,"distance":9.478,"estimated_hours":0,"ref_bonus_amount":0,"canceled_by":"none","attachment":null,"cancella …[truncated]
```

### PUT `api/v1/rental/vendor/trip/edit-trip`

- **Auth:** `vendor`
- **Parameters:** `trip_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/rental/vendor/trip/edit-trip' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"trip_id":100031}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"coordinates","message":"You can not edit this"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/rental/vendor/trip/list/{all}`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/trip/list/all?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":100237,"user_id":8,"provider_id":60,"zone_id":1,"module_id":6,"pickup_zone_id":1,"cash_back_id":null,"trip_amount":81.25,"discount_on_trip":2.5,"discount_on_trip_by":"vendor","coupon_discount_amount":0,"coupon_discount_by":"none","coupon_code":null,"trip_status":"pending","payment_status":"unpaid","payment_method":null,"transaction_reference":null,"tax_amount":23.75,"tax_status":"excluded","tax_percentage":0,"trip_type":"hourly","additional_charge":10,"partially_paid_amount":0,"distance":12.076,"estimated_hours":1,"ref_bonus_amount":0,"canceled_by":"none","attachment":null,"cancellation_reason":null,"pi …[truncated]
```

### GET `api/v1/rental/vendor/trip/payment`

- **Auth:** `vendor`
- **Parameters:** `trip_id` (**required**), `payment_method` (optional), `transaction_reference` (optional), `payment_status` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/trip/payment?trip_id=100031&payment_method=cash_on_delivery&transaction_reference=test&payment_status=paid' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":null,"errors":[]}
```

### GET `api/v1/rental/vendor/trip/status`

- **Auth:** `vendor`
- **Parameters:** `trip_id` (**required**), `cancellation_reason` (optional), `trip_status` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/trip/status?trip_id=100031&cancellation_reason=test&trip_status=confirmed' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"trip_status","message":"You cannot change this trip status"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/rental/vendor/update-business-setup`

- **Auth:** `vendor`
- **Parameters:** `contact_number` (**required**), `schedule_trip` (**required**), `gst` (conditional — `required_if:gst_status,1`), `minimum_pickup_time` (**required**), `maximum_pickup_time` (**required**), `pickup_time_type` (**required**), `logo` (optional), `cover_photo` (optional), `meta_image` (optional), `translations` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/update-business-setup' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"contact_number":"+101747410000","schedule_trip":1,"gst":"test","minimum_pickup_time":"09:00","maximum_pickup_time":"09:00","pickup_time_type":"min","translations":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The contact number has already been taken.","content":null,"errors":{"contact_number":["The contact number has already been taken."],"minimum_pickup_time":["The minimum pickup time must be a number."],"maximum_pickup_time":["The maximum pickup time must be a number."],"translations":["Name and address in english is required"]}}
```
- *Takes file upload(s) not exercised here: `logo`, `cover_photo`, `meta_image` — send as `multipart/form-data`.*

### POST `api/v1/rental/vendor/vehicle/ai/generate-form-image`

- **Auth:** `vendor`
- **Parameters:** `image` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/vehicle/ai/generate-form-image' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Image is required","content":null,"errors":{"image":["Image is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### GET `api/v1/rental/vendor/vehicle/ai/generate-other-data`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**), `description` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/vehicle/ai/generate-other-data?name=Audit+Probe&description=Audit+probe+description' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Validation failed","content":null,"errors":[{"code":"ai","message":"AI failed to generate a result. Please try again."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/rental/vendor/vehicle/ai/generate-title-and-description`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**), `langCode` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/vehicle/ai/generate-title-and-description?name=Audit+Probe&langCode=en' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Validation failed","content":null,"errors":[{"code":"ai","message":"AI failed to generate a result. Please try again."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/rental/vendor/vehicle/ai/generate-title-suggestions`

- **Auth:** `vendor`
- **Parameters:** `keywords` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/vehicle/ai/generate-title-suggestions?keywords=test&name=Toyota' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Validation failed","content":null,"errors":[{"code":"ai","message":"AI failed to generate a result. Please try again."}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/rental/vendor/vehicle/create`

- **Auth:** `vendor`
- **Parameters:** `category_id` (**required**), `brand_id` (**required**), `translations` (**required**), `discount_type` (**required**), `discount_price` (optional), `vehicle` (**required**), `vehicle.vin_number` (**required**), `vehicle.license_plate_number` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/vehicle/create' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"category_id":2,"brand_id":2,"translations":"test","discount_type":"percent","discount_price":"test","vehicle":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Discount must be numeric","content":null,"errors":{"discount_price":["Discount must be numeric","Discount cannot exceed 100 percent"],"vehicle":["The vehicle field is required."],"vehicle.vin_number":["The vehicle.vin number field is required."],"vehicle.license_plate_number":["The vehicle.license plate number field is required."],"translations":["Name and description in english is required"]}}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/rental/vendor/vehicle/delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/rental/vendor/vehicle/delete/43' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":null,"errors":[]}
```

### GET `api/v1/rental/vendor/vehicle/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/vehicle/details/43' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":43,"name":"Toyota Corolla","slug":"toyota-corolla","description":"Daily Commuting (Economical and Efficient)","zone_id":1,"provider_id":60,"brand_id":1,"category_id":1,"model":"Toyota700","type":"compact","engine_capacity":"1000","engine_power":"25000","seating_capacity":"4","air_condition":1,"fuel_type":"octan","transmission_type":"automatic","multiple_vehicles":1,"trip_hourly":1,"trip_distance":1,"trip_day_wise":0,"day_wise_price":0,"hourly_price":250,"distance_price":500,"discount_type":"percent","discount_price":10,"tag":["new","car"],"status":1,"new_tag":1,"total_trip":4,"avg_rating":4,"rating":"{\"1\":0,\" …[truncated]
```

### GET `api/v1/rental/vendor/vehicle/edit/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/vehicle/edit/43' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":43,"name":"Toyota Corolla","slug":"toyota-corolla","description":"Daily Commuting (Economical and Efficient)","zone_id":1,"provider_id":60,"brand_id":1,"category_id":1,"model":"Toyota700","type":"compact","engine_capacity":"1000","engine_power":"25000","seating_capacity":"4","air_condition":1,"fuel_type":"octan","transmission_type":"automatic","multiple_vehicles":1,"trip_hourly":1,"trip_distance":1,"trip_day_wise":0,"day_wise_price":0,"hourly_price":250,"distance_price":500,"discount_type":"percent","discount_price":10,"tag":["new","car"],"status":1,"new_tag":1,"total_trip":4,"avg_rating":4,"rating":"{\"1\":0,\" …[truncated]
```

### GET `api/v1/rental/vendor/vehicle/list`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/vehicle/list?limit=10&offset=1&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/vendor/vehicle/new-tag/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/vehicle/new-tag/43' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":null,"errors":[]}
```

### PUT `api/v1/rental/vendor/vehicle/reply-update`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `reply` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/rental/vendor/vehicle/reply-update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1,"reply":"test"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":null,"errors":[]}
```

### GET `api/v1/rental/vendor/vehicle/reviews`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/vehicle/reviews?limit=10&offset=1&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/rental/vendor/vehicle/status/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/rental/vendor/vehicle/status/43' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":null,"errors":[]}
```

### POST `api/v1/rental/vendor/vehicle/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `category_id` (**required**), `brand_id` (**required**), `translations` (**required**), `discount_type` (**required**), `discount_price` (optional), `vehicle` (**required**), `vehicle.vin_number` (**required**), `vehicle.license_plate_number` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/rental/vendor/vehicle/update/43' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 6' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"category_id":2,"brand_id":2,"translations":"test","discount_type":"percent","discount_price":"test","vehicle":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Discount must be numeric","content":null,"errors":{"discount_price":["Discount must be numeric","Discount cannot exceed 100 percent"],"vehicle":["The vehicle field is required."],"vehicle.vin_number":["The vehicle.vin number field is required."],"vehicle.license_plate_number":["The vehicle.license plate number field is required."],"translations":["Name and description in english is required"]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/service/basic-campaigns`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/basic-campaigns' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[],"errors":[]}
```

### GET `api/v1/service/basic-campaigns/details/{id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/basic-campaigns/details/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/service/booking/all-running-bookings`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/booking/all-running-bookings?guest_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":102674,"order_type":"service_booking","status":"accepted","is_repeat":0,"created_at":"2026-08-21T07:43:14.000000Z"}]},"errors":[]}
```

### POST `api/v1/service/booking/cancel`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `booking_id` (**required**), `cancellation_reason` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/booking/cancel' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","booking_id":102673,"cancellation_reason":"test"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"booking","message":"Booking already canceled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/service/booking/delete`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `booking_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/service/booking/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","booking_id":102673}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":{"message":"Booking removed successfully"},"errors":[]}
```

### GET `api/v1/service/booking/details/{id}`

- **Auth:** `customer_or_guest`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/booking/details/102673' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"booking","message":"Booking not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/service/booking/get-tax`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `provider_id` (**required**), `selected_bid_id` (optional), `buy_now` (optional), `is_campaign` (optional), `service_id` (optional), `repeat_count` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/booking/get-tax?guest_id=1&provider_id=60&selected_bid_id=1&buy_now=0&is_campaign=0&service_id=1&repeat_count=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The repeat count must be an integer.","content":null,"errors":{"repeat_count":["The repeat count must be an integer."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/service/booking/invoice/{id}`

- **Auth:** `customer_or_guest`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/booking/invoice/102673' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"booking","message":"Booking not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/service/booking/last`

- **Auth:** `customer_or_guest`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/booking/last' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":1,"limit":10,"offset":1,"bookings":[{"id":102675,"display_id":"102675","booking_type":"regular","multi_booking_type":null,"parent_booking_id":null,"is_repeat_parent":false,"child_bookings_count":0,"active_booking_id":102675,"active_display_id":"102675","active_booking_status":"completed","active_status_label":"Completed","active_schedule_at":"2026-08-27 13:43:14","is_custom":false,"is_campaign":false,"booking_status":"completed","status_label":"Completed","payment_status":"paid","payment_method":"cash_on_delivery","scheduled":0,"schedule_at":"2026-08-27 13:43:14","quantity":1,"details_count":1,"services" …[truncated]
```

### GET `api/v1/service/booking/list`

- **Auth:** `customer_or_guest`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/booking/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":3,"limit":10,"offset":1,"bookings":[{"id":102676,"display_id":"102676","booking_type":"regular","multi_booking_type":null,"parent_booking_id":null,"is_repeat_parent":false,"child_bookings_count":0,"active_booking_id":102676,"active_display_id":"102676","active_booking_status":"canceled","active_status_label":"Canceled","active_schedule_at":"2026-08-28 13:43:14","is_custom":false,"is_campaign":false,"booking_status":"canceled","status_label":"Canceled","payment_status":"unpaid","payment_method":"cash_on_delivery","scheduled":0,"schedule_at":"2026-08-28 13:43:14","quantity":1,"details_count":1,"services":[ …[truncated]
```

### GET `api/v1/service/booking/log/{id}`

- **Auth:** `customer_or_guest`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/booking/log/102673' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"booking","message":"Booking not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/service/booking/payment`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `booking_id` (**required**), `payment_method` (**required**), `partial_payment_method` (optional), `payment_gateway` (conditional — `required_if:payment_method,digital_payment`), `method_id` (conditional — `required_if:payment_method,offline_payment`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/booking/payment' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","booking_id":102673,"payment_method":"cash_after_service","partial_payment_method":"cash_after_service","payment_gateway":"test","method_id":1}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"booking_id":102673,"payment_method":"cash_after_service","payment_status":"unpaid","partially_paid_amount":0},"errors":[]}
```

### POST `api/v1/service/booking/place`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `payment_method` (**required**), `partial_payment_method` (optional), `method_id` (conditional — `required_if:payment_method,offline_payment`), `bring_change_amount` (optional), `attachments` (optional), `attachments.*` (optional), `provider_id` (**required**), `selected_bid_id` (optional), `buy_now` (optional), `is_campaign` (optional), `service_id` (optional), `quantity` (optional), `description` (optional), `service_location` (**required**), `schedule_at` (optional), `scheduled` (optional), `booking_type` (optional), `multi_booking_type` (conditional — `required_if:booking_type,repeat`), `dates` (conditional — `required_if:booking_type,repeat`), `contact_person_name` (**required**), `contact_person_number` (**required**), `contact_person_email` (**required**), `password` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/booking/place' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","payment_method":"cash_after_service","partial_payment_method":"cash_after_service","method_id":1,"bring_change_amount":"test","attachments":[],"provider_id":60,"selected_bid_id":1,"buy_now":"0","is_campaign":"0","service_id":1,"quantity":1,"description":"Audit probe description","service_location":"test","schedule_at":"2026-08-27","scheduled":"0","booking_type":"regular","multi_booking_type":"daily","dates":"2026-08-27","contact_person_name":"test","contact_person_number":"+8801700000000","contact_person_email":"6amtech@gmail.com","password":"Str0ng@Pass1"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The bring change amount must be a number.","content":null,"errors":{"bring_change_amount":["The bring change amount must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/service/booking/rebook`

- **Auth:** `customer_or_guest`
- **Parameters:** `booking_id` (**required**), `guest_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/booking/rebook' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"booking_id":102673,"guest_id":"1"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"booking","message":"Reorder feature is not available"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/service/booking/reschedule`

- **Auth:** `customer_or_guest`
- **Parameters:** `guest_id` (**required**), `booking_id` (**required**), `service_schedule` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/booking/reschedule' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"guest_id":"1","booking_id":102673,"service_schedule":"2026-08-27"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The service schedule must be a date after now.","content":null,"errors":{"service_schedule":["The service schedule must be a date after now."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/service/booking/track`

- **Auth:** `public`
- **Parameters:** `booking_id` (**required**), `contact_number` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/booking/track?booking_id=102673&contact_number=%2B8801700000000' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"booking","message":"Booking not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/service/campaigns`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/campaigns?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":4,"limit":10,"offset":1,"campaigns":[{"id":4,"name":"Monsoon Offer","slug":"monsoon-offer-sd","short_description":"Monsoon Offer short","long_description":"Monsoon Offer long","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":700,"min_bid_price":null,"discount":15,"discount_type":"percent","discounted_price":595,"variations":[],"tags":[],"module_id":16,"store_id":229,"category_id":2,"sub_category_id":null,"store_category_id":null,"category":{"id":2,"name":"Personal Care","slug":"seafood2"},"sub_category":null,"store_category":null,"provider_name":"Seed Service Provider","provider_ima …[truncated]
```

### GET `api/v1/service/campaigns/details/{id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/campaigns/details/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":1,"name":"Monsoon Offer","slug":"monsoon-offer-sd","short_description":"Monsoon Offer short","long_description":"Monsoon Offer long","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":700,"min_bid_price":null,"discount":15,"discount_type":"percent","discounted_price":595,"variations":[],"tags":[],"module_id":16,"store_id":2,"category_id":2,"sub_category_id":null,"store_category_id":null,"category":{"id":2,"name":"Personal Care","slug":"seafood2"},"sub_category":null,"store_category":null,"provider_name":"Click & Collect","provider_image_full_url":"{{host}}\/storage\/app\/public\/store\/2022-0 …[truncated]
```

### GET `api/v1/service/category-providers`

- **Auth:** `public`
- **Parameters:** `category_id` (**required**), `limit` (optional), `offset` (optional), `sub_category_id` (optional), `preview_count` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/category-providers?category_id=2&limit=10&offset=1&sub_category_id=1&preview_count=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The preview count must be an integer.","content":null,"errors":{"preview_count":["The preview count must be an integer."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/service/custom-requests`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/custom-requests' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":13,"description":"Audit fixture custom service request","category_id":2,"category_name":"Personal Care","category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c71a0338d.png","sub_category_id":null,"sub_category_name":null,"status":"pending","status_label":"Pending","is_expired":false,"bid_count":0,"offer":null,"created_at":"2026-08-27"}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### POST `api/v1/service/custom-requests`

- **Auth:** `customer`
- **Parameters:** `category_id` (**required**), `sub_category_id` (optional), `description` (**required**), `customer_information` (optional), `customer_information.name` (optional), `customer_information.phone` (optional), `customer_information.address` (optional), `customer_information.latitude` (optional), `customer_information.longitude` (optional), `customer_information.house` (optional), `customer_information.road` (optional), `customer_information.floor` (optional), `booking_date` (optional), `booking_time` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/custom-requests' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"category_id":1,"sub_category_id":1,"description":"Audit probe description","customer_information":[],"booking_date":"2026-08-27","booking_time":"2026-08-27"}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The Sub Category and Category must be different. (and 1 more error)","errors":{"sub_category_id":["The Sub Category and Category must be different."],"booking_time":["The booking time does not match the format H:i."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/service/custom-requests/{customServiceRequest}`

- **Auth:** `customer`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/service/custom-requests/13' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":null,"errors":[]}
```

### GET `api/v1/service/custom-requests/{customServiceRequest}`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/custom-requests/13' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":{"id":13,"description":"Audit fixture custom service request","customer_information":{"name":"Audit Fixture","phone":"+8801700000000","address":"Audit fixture address","latitude":"23.735129","longitude":"90.425614"},"booking_date":"2026-08-30","booking_time":"10:00:00","status":"pending","status_label":"Pending","is_expired":false,"bid_count":0,"last_bid_at":null,"selected_offer_id":null,"category":{"id":2,"name":"Personal Care","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c71a0338d.png"},"sub_category":null,"selected_offer":null,"created_at":"2026-08-27T08:12:54.000000Z","updated …[truncated]
```

### PUT `api/v1/service/custom-requests/{customServiceRequest}`

- **Auth:** `customer`
- **Parameters:** `category_id` (optional), `sub_category_id` (optional), `description` (optional), `customer_information` (optional), `customer_information.name` (optional), `customer_information.phone` (optional), `customer_information.address` (optional), `customer_information.latitude` (optional), `customer_information.longitude` (optional), `booking_date` (optional), `booking_time` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/service/custom-requests/13' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"category_id":1,"sub_category_id":1,"description":"Audit probe description","customer_information":[],"booking_date":"2026-08-27","booking_time":"2026-08-27"}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The sub category id and category id must be different. (and 1 more error)","errors":{"sub_category_id":["The sub category id and category id must be different."],"booking_time":["The booking time does not match the format H:i."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/service/custom-requests/{customServiceRequest}/bid-status`

- **Auth:** `customer`
- **Parameters:** `offer_id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/custom-requests/13/bid-status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"offer_id":1,"status":1}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The selected Bid is invalid. (and 2 more errors)","errors":{"offer_id":["The selected Bid is invalid."],"status":["The status must be a string.","The selected status is invalid."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/service/details/{id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/details/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":1,"name":"Deep Cleaning","slug":"deep-cleaning-sd","short_description":"Deep Cleaning short","long_description":"Deep Cleaning long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":1200,"discount":0,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":1,"is_approved":1,"status":1,"order_count":24,"avg_rating":4.5,"rating_count":2,"module_id":16,"module_type":"service","store_id":2,"store_name":"Click & Collect","provider_name":"Click & Collect","provider_image_full_url":"{{host}}\/storage\/app\/public\/store\/2022-03-2 …[truncated]
```

### GET `api/v1/service/explore`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/explore?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":6,"limit":10,"offset":1,"services":[{"id":6,"name":"Sofa Shampoo","slug":"sofa-shampoo-sd","short_description":"Sofa Shampoo short","long_description":"Sofa Shampoo long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":999,"discount":10,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":0,"is_approved":1,"status":1,"order_count":4,"avg_rating":4.5,"rating_count":5,"module_id":16,"module_type":"service","store_id":4,"store_name":"Health Life","provider_name":"Health Life","provider_image_full_url":"{{host}}\/s …[truncated]
```

### GET `api/v1/service/get-combined-data`

- **Auth:** `public`
- **Parameters:** `list_type` (**required**), `data_type` (optional), `name` (conditional — `required_if:data_type,searched`), `category_ids` (conditional — `required_if:data_type,category`), `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/get-combined-data?list_type=item&data_type=test&name=Audit+Probe&category_ids%5B0%5D=2&limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":3,"limit":10,"offset":1,"products":[{"id":5,"name":"Pest Control","slug":"pest-control-sd","short_description":"Pest Control short","long_description":"Pest Control long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":2200,"discount":0,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":0,"is_approved":1,"status":1,"order_count":8,"avg_rating":4.5,"rating_count":4,"module_id":16,"module_type":"service","store_id":3,"store_name":"Eorange","provider_name":"Eorange","provider_image_full_url":"{{host}}\/storage\/ …[truncated]
```

### GET `api/v1/service/item-or-store-search`

- **Auth:** `public`
- **Parameters:** `name` (**required**), `is_global` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/item-or-store-search?name=Deep&is_global=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"items":[{"id":1,"name":"Deep Cleaning","image":null,"image_full_url":null,"module_id":16,"module":{"id":16,"name":"Service","image":null,"type":"service"}}],"stores":[]},"errors":[]}
```

### GET `api/v1/service/latest`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/latest?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":6,"limit":10,"offset":1,"services":[{"id":6,"name":"Sofa Shampoo","slug":"sofa-shampoo-sd","short_description":"Sofa Shampoo short","long_description":"Sofa Shampoo long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":999,"discount":10,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":0,"is_approved":1,"status":1,"order_count":4,"avg_rating":4.5,"rating_count":5,"module_id":16,"module_type":"service","store_id":4,"store_name":"Health Life","provider_name":"Health Life","provider_image_full_url":"{{host}}\/s …[truncated]
```

### GET `api/v1/service/offers/items`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/offers/items?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":3,"limit":10,"offset":1,"services":[{"id":2,"name":"AC Repair","slug":"ac-repair-sd","short_description":"AC Repair short","long_description":"AC Repair long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":850,"discount":10,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":1,"is_approved":1,"status":1,"order_count":20,"avg_rating":4.5,"rating_count":1,"module_id":16,"module_type":"service","store_id":3,"store_name":"Eorange","provider_name":"Eorange","provider_image_full_url":"{{host}}\/storage\/app\/public …[truncated]
```

### GET `api/v1/service/popular`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/popular?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":6,"limit":10,"offset":1,"services":[{"id":1,"name":"Deep Cleaning","slug":"deep-cleaning-sd","short_description":"Deep Cleaning short","long_description":"Deep Cleaning long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":1200,"discount":0,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":1,"is_approved":1,"status":1,"order_count":24,"avg_rating":4.5,"rating_count":2,"module_id":16,"module_type":"service","store_id":2,"store_name":"Click & Collect","provider_name":"Click & Collect","provider_image_full_url" …[truncated]
```

### GET `api/v1/service/query`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/query?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":6,"limit":10,"offset":1,"services":[{"id":6,"name":"Sofa Shampoo","slug":"sofa-shampoo-sd","short_description":"Sofa Shampoo short","long_description":"Sofa Shampoo long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":999,"discount":10,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":0,"is_approved":1,"status":1,"order_count":4,"avg_rating":4.5,"rating_count":5,"module_id":16,"module_type":"service","store_id":4,"store_name":"Health Life","provider_name":"Health Life","provider_image_full_url":"{{host}}\/s …[truncated]
```

### GET `api/v1/service/quick-emergency-experts`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/quick-emergency-experts?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":0,"limit":10,"offset":1,"providers":[]},"errors":[]}
```

### GET `api/v1/service/recommended`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/recommended?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":3,"limit":10,"offset":1,"services":[{"id":2,"name":"AC Repair","slug":"ac-repair-sd","short_description":"AC Repair short","long_description":"AC Repair long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":850,"discount":10,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":1,"is_approved":1,"status":1,"order_count":20,"avg_rating":4.5,"rating_count":1,"module_id":16,"module_type":"service","store_id":3,"store_name":"Eorange","provider_name":"Eorange","provider_image_full_url":"{{host}}\/storage\/app\/public …[truncated]
```

### GET `api/v1/service/related-provider-services/{service_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/related-provider-services/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[{"id":4,"name":"Electrical Wiring","slug":"electrical-wiring-sd","short_description":"Electrical Wiring short","long_description":"Electrical Wiring long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":1500,"discount":10,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":0,"is_approved":1,"status":1,"order_count":12,"avg_rating":0,"rating_count":0,"module_id":16,"module_type":"service","store_id":2,"store_name":"Click & Collect","provider_name":"Click & Collect","provider_image_full_url":"{{host}}\/storage\/app\/public\/ …[truncated]
```

### GET `api/v1/service/related/{service_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/related/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[{"id":5,"name":"Pest Control","slug":"pest-control-sd","short_description":"Pest Control short","long_description":"Pest Control long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":2200,"discount":0,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":0,"is_approved":1,"status":1,"order_count":8,"avg_rating":4.5,"rating_count":4,"module_id":16,"module_type":"service","store_id":3,"store_name":"Eorange","provider_name":"Eorange","provider_image_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27-671e34990da6e.png" …[truncated]
```

### GET `api/v1/service/requested-services`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/requested-services' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":23,"service_name":"test","description":"Audit probe description","category_id":1,"category_name":"Baby Care","category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","sub_category_id":1,"sub_category_name":"Baby Care","sub_category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","status":"pending","status_label":"Pending","can_edit":true,"can_delete":true,"created_at":"2026-08-27 13:59:17"},{"id":22,"service_name":"test","description":"Audit probe description","category_id":1,"category_name":"Baby Care","category_image_fu …[truncated]
```

### POST `api/v1/service/requested-services`

- **Auth:** `customer`
- **Parameters:** `category_id` (**required**), `sub_category_id` (optional), `service_name` (**required**), `description` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/requested-services' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"category_id":1,"sub_category_id":1,"service_name":"test","description":"Audit probe description"}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Successfully created","content":{"id":24,"service_name":"test","description":"Audit probe description","category_id":1,"category_name":"Baby Care","category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","sub_category_id":1,"sub_category_name":"Baby Care","sub_category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","status":"pending","status_label":"Pending","feedback":null,"can_edit":true,"can_delete":true,"created_at":"2026-08-27 14:13:26","updated_at":"2026-08-27 14:13:26"},"errors":[]}
```

### DELETE `api/v1/service/requested-services/{serviceRequest}`

- **Auth:** `customer`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/service/requested-services/17' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":null,"errors":[]}
```

### GET `api/v1/service/requested-services/{serviceRequest}`

- **Auth:** `customer`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/requested-services/17' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":17,"service_name":"test","description":"Audit probe description","category_id":1,"category_name":"Baby Care","category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","sub_category_id":1,"sub_category_name":"Baby Care","sub_category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","status":"pending","status_label":"Pending","feedback":null,"can_edit":true,"can_delete":true,"created_at":"2026-08-27 13:43:24","updated_at":"2026-08-27 13:43:24"},"errors":[]}
```

### PUT `api/v1/service/requested-services/{serviceRequest}`

- **Auth:** `customer`
- **Parameters:** `category_id` (**required**), `sub_category_id` (optional), `service_name` (**required**), `description` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/service/requested-services/17' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"category_id":1,"sub_category_id":1,"service_name":"test","description":"Audit probe description"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":{"id":17,"service_name":"test","description":"Audit probe description","category_id":1,"category_name":"Baby Care","category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","sub_category_id":1,"sub_category_name":"Baby Care","sub_category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","status":"pending","status_label":"Pending","feedback":null,"can_edit":true,"can_delete":true,"created_at":"2026-08-27 13:43:24","updated_at":"2026-08-27 13:43:24"},"errors":[]}
```

### POST `api/v1/service/requested-services/{serviceRequest}/cancel`

- **Auth:** `customer`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/requested-services/17/cancel' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":{"id":17,"service_name":"test","description":"Audit probe description","category_id":1,"category_name":"Baby Care","category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","sub_category_id":1,"sub_category_name":"Baby Care","sub_category_image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c7280b472.png","status":"cancelled","status_label":"Cancelled","feedback":null,"can_edit":false,"can_delete":true,"created_at":"2026-08-27 13:43:24","updated_at":"2026-08-27 14:13:27"},"errors":[]}
```

### GET `api/v1/service/reviews/rating/{service_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/reviews/rating/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"avg_rating":4.67,"total_reviews":3},"errors":[]}
```

### POST `api/v1/service/reviews/submit`

- **Auth:** `customer`
- **Parameters:** `service_id` (**required**), `booking_id` (**required**), `rating` (**required**), `comment` (optional), `attachment` (optional), `attachment.*` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/reviews/submit' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{user_token}}' \
  -d '{"service_id":1,"booking_id":102673,"rating":"test","comment":"test","attachment":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The rating must be a number.","content":null,"errors":{"rating":["The rating must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/service/reviews/{service_id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/reviews/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"rating_summary":{"avg_rating":4.67,"total_reviews":3,"breakdown":[{"label":"excellent","star":5,"count":2},{"label":"good","star":4,"count":1},{"label":"average","star":3,"count":0},{"label":"below","star":2,"count":0},{"label":"poor","star":1,"count":0}]},"data":[{"id":6,"review_id":"SD-0","service_id":1,"booking_id":null,"rating":5,"comment":"Excellent work","attachment":[],"reply":null,"replied_at":null,"service_name":"Deep Cleaning","customer":{"id":8,"f_name":"Audit","l_name":"Probe","image_full_url":"{{host}}\/storage\/app\/public\/profile\/2026-07-02-6a45fd3b80ee9.webp"},"review_date":"27 August 2026","review …[truncated]
```

### GET `api/v1/service/search`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/search?limit=10&offset=1&name=Deep' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":1,"limit":10,"offset":1,"services":[{"id":1,"name":"Deep Cleaning","slug":"deep-cleaning-sd","short_description":"Deep Cleaning short","long_description":"Deep Cleaning long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":1200,"discount":0,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":1,"is_approved":1,"status":1,"order_count":24,"avg_rating":4.5,"rating_count":2,"module_id":16,"module_type":"service","store_id":2,"store_name":"Click & Collect","provider_name":"Click & Collect","provider_image_full_url" …[truncated]
```

### GET `api/v1/service/search-suggestion`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/search-suggestion?limit=10&offset=1&name=Deep' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":1,"limit":10,"offset":1,"services":[{"id":1,"name":"Deep Cleaning","slug":"deep-cleaning-sd","thumbnail_full_url":null}]},"errors":[]}
```

### GET `api/v1/service/service-module/status`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/service-module/status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"module":"Service","status":"ok"}
```

### POST `api/v1/service/serviceman/auth/forgot-password`

- **Auth:** `public`
- **Parameters:** `phone` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/serviceman/auth/forgot-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -d '{"phone":"+8801700000000"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"not-found","message":"Phone number not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/service/serviceman/auth/login`

- **Auth:** `public`
- **Parameters:** `phone` (**required**), `password` (**required**), `fcm_token` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/serviceman/auth/login' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -d '{"phone":"+8801700000903","password":"Str0ng@Pass1"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"token":"<REDACTED>","provider_id":229,"zone_id":1,"topic":"serviceman_229","zone_topic":"serviceman_zone_1"},"errors":[]}
```

### POST `api/v1/service/serviceman/auth/logout`

- **Auth:** `serviceman`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/serviceman/auth/logout' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}' \
  -d '{"token":"{{serviceman_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"message":"Logout successful"},"errors":[]}
```

### PUT `api/v1/service/serviceman/auth/reset-password`

- **Auth:** `public`
- **Parameters:** `phone` (**required**), `reset_token` (**required**), `password` (**required**), `confirm_password` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/service/serviceman/auth/reset-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -d '{"phone":"+8801700000000","reset_token":"test","password":"Str0ng@Pass1","confirm_password":"Str0ng@Pass1"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"not-found","message":"Phone number not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/service/serviceman/auth/verify-token`

- **Auth:** `public`
- **Parameters:** `phone` (**required**), `reset_token` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/serviceman/auth/verify-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -d '{"phone":"+8801700000000","reset_token":"test"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"not-found","message":"Phone number not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/service/serviceman/booking/detail/{id}`

- **Auth:** `serviceman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/serviceman/booking/detail/102692?token={{serviceman_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":102692,"display_id":"SVCSEED-101","booking_type":"regular","multi_booking_type":null,"parent_booking_id":null,"is_repeat_parent":false,"child_bookings_count":0,"is_custom":false,"is_campaign":false,"can_rebook":false,"booking_status":"accepted","status_label":"Accepted","status_history":null,"status_histories":[],"payment_status":"unpaid","payment_method":"cash_on_delivery","transaction_reference":null,"scheduled":0,"schedule_at":"2026-08-26 15:25:13","quantity":1,"booking_note":null,"bring_change_amount":0,"attachments":[],"completion_evidence":[],"cancellation_reason":null,"canceled_by":"none","service_locatio …[truncated]
```

### GET `api/v1/service/serviceman/booking/invoice/{id}`

- **Auth:** `serviceman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/serviceman/booking/invoice/102692?token={{serviceman_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}'
```
- **Status:** 200
- **Response:**
```json
%PDF-1.4 %???? 3 0 obj <</Type /Page /Parent 1 0 R /MediaBox [0 0 538.583 708.661] /TrimBox [0.000 0.000 538.583 708.661] /Resources 2 0 R /Group << /Type /Group /S /Transparency /CS /DeviceRGB >> /Contents 4 0 R>> endobj 4 0 obj <</Filter /FlateDecode /Length 1865>> stream x??Y[o5??? K????}|G??MJ? P?DHxI?I?Mz????3ޙm??ٴ???ڳ>??\?$?,??!??????F&E^????>^i?壅)ϓ??G{F?\?%???????G?\??Z??-ߓ?' ?T?Z:<} i?pV?!??_???uk?V?ض?䠢?S?J{j?=??'.??*cb[ Z>????q???a????sŞI?IXp"%c.? $??28@?I?I??x,??;??Cq??????? ?2y? ߋā?&o?21u???R??sq"??B?_??q?;?-̊?T.?5.??@???[p ?A??x ~w0???ka?߾g+~?????._?~u??iTb??<<?w???? yg"* ?(?r?D?g?'?/?̛[ق?U):4?5??????{<+?????>Oa?S …[truncated]
```

### GET `api/v1/service/serviceman/booking/list`

- **Auth:** `serviceman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/serviceman/booking/list?token={{serviceman_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":1,"limit":10,"offset":1,"bookings":[{"id":102692,"display_id":"102692","booking_type":"regular","multi_booking_type":null,"parent_booking_id":null,"is_repeat_parent":false,"child_bookings_count":0,"active_booking_id":102692,"active_display_id":"102692","active_booking_status":"accepted","active_status_label":"Accepted","active_schedule_at":"2026-08-26 15:25:13","is_custom":false,"is_campaign":false,"booking_status":"accepted","status_label":"Accepted","payment_status":"unpaid","payment_method":"cash_on_delivery","scheduled":0,"schedule_at":"2026-08-26 15:25:13","quantity":1,"details_count":1,"services":[ …[truncated]
```

### GET `api/v1/service/serviceman/booking/log/{id}`

- **Auth:** `serviceman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/serviceman/booking/log/102692?token={{serviceman_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"booking","message":"Service log is only available for repeat bookings"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/service/serviceman/booking/repeat/status-update/{id}`

- **Auth:** `serviceman`
- **Parameters:** `booking_status` (**required**), `cancellation_reason` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/service/serviceman/booking/repeat/status-update/102692' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}' \
  -d '{"booking_status":"test","cancellation_reason":"test","token":"{{serviceman_token}}"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"booking","message":"Booking not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/service/serviceman/booking/send-otp/{id}`

- **Auth:** `serviceman`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/serviceman/booking/send-otp/102692' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}' \
  -d '{"token":"{{serviceman_token}}"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"otp","message":"Otp verification is not enabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/service/serviceman/booking/status-update/{id}`

- **Auth:** `serviceman`
- **Parameters:** `booking_status` (**required**), `cancellation_reason` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/service/serviceman/booking/status-update/102692' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}' \
  -d '{"booking_status":"test","cancellation_reason":"test","token":"{{serviceman_token}}"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"booking_status","message":"Invalid status"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/service/serviceman/change-password`

- **Auth:** `serviceman`
- **Parameters:** `password` (**required**), `confirm_password` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/service/serviceman/change-password' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}' \
  -d '{"password":"Str0ng@Pass1","confirm_password":"Str0ng@Pass1","token":"{{serviceman_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"message":"Password changed successfully."},"errors":[]}
```

### GET `api/v1/service/serviceman/dashboard`

- **Auth:** `serviceman`
- **Parameters:** `sections` (**required**), `sections.*` (optional), `range` (optional), `booking_status` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/serviceman/dashboard?range=this_week&booking_status=all&token={{serviceman_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"top_cards":{"total_bookings":1,"ongoing_bookings":0,"completed_bookings":0,"canceled_bookings":0},"booking_stats":{"categories":["Mon","Tue","Wed","Thu","Fri","Sat","Sun"],"series":[0,0,1500,0,0,0,0]},"recent_bookings":[{"id":102692,"display_id":"102692","booking_type":"regular","multi_booking_type":null,"parent_booking_id":null,"is_repeat_parent":false,"child_bookings_count":0,"active_booking_id":102692,"active_display_id":"102692","active_booking_status":"accepted","active_status_label":"Accepted","active_schedule_at":"2026-08-26 15:25:13","is_custom":false,"is_campaign":false,"booking_status":"accepted","status_l …[truncated]
```

### GET `api/v1/service/serviceman/info`

- **Auth:** `serviceman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/serviceman/info?token={{serviceman_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":9,"f_name":"Seed","l_name":"Serviceman","full_name":"Seed Serviceman","email":"svcseed.sm0@mart.test","phone":"+8801700000903","image_full_url":null,"identity_type":"passport","identity_number":"test","identity_image_full_url":[],"zone_id":1,"type":"full_time","status":true,"active":true,"application_status":"approved","member_since_days":1,"booking_count":0,"assigned_booking_count":0,"current_bookings":0,"total_assigned":1,"ongoing_bookings":0,"completed_bookings":0,"canceled_bookings":0,"provider":{"id":229,"name":"Seed Service Provider","phone":"+8801700000902","zone_id":1,"logo_full_url":null,"serviceman_can …[truncated]
```

### GET `api/v1/service/serviceman/notifications`

- **Auth:** `serviceman`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/serviceman/notifications?token={{serviceman_token}}' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[],"errors":[]}
```

### PUT `api/v1/service/serviceman/update/fcm-token`

- **Auth:** `serviceman`
- **Parameters:** `fcm_token` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/service/serviceman/update/fcm-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}' \
  -d '{"fcm_token":"test","token":"{{serviceman_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"message":"Successfully updated"},"errors":[]}
```

### POST `api/v1/service/serviceman/update/profile`

- **Auth:** `serviceman`
- **Parameters:** `f_name` (**required**), `l_name` (optional), `email` (**required**), `phone` (**required**), `password` (optional), `image` (optional), `fcm_token` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/service/serviceman/update/profile' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'Authorization: Bearer {{serviceman_token}}' \
  -d '{"f_name":"Audit","l_name":"Probe","email":"svcseed.sm0@mart.test","phone":"+8801700000903","password":"Str0ng@Pass1","fcm_token":"test","token":"{{serviceman_token}}"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"message":"Successfully updated"},"errors":[]}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### GET `api/v1/service/suggested`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional), `store_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/suggested?limit=10&offset=1&store_id=3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":2,"limit":10,"offset":1,"services":[{"id":2,"name":"AC Repair","slug":"ac-repair-sd","short_description":"AC Repair short","long_description":"AC Repair long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":850,"discount":10,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":1,"is_approved":1,"status":1,"order_count":20,"avg_rating":4.5,"rating_count":1,"module_id":16,"module_type":"service","store_id":3,"store_name":"Eorange","provider_name":"Eorange","provider_image_full_url":"{{host}}\/storage\/app\/public …[truncated]
```

### GET `api/v1/service/top-rated`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/service/top-rated?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":6,"limit":10,"offset":1,"services":[{"id":1,"name":"Deep Cleaning","slug":"deep-cleaning-sd","short_description":"Deep Cleaning short","long_description":"Deep Cleaning long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":1200,"discount":0,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":1,"is_approved":1,"status":1,"order_count":24,"avg_rating":4.5,"rating_count":2,"module_id":16,"module_type":"service","store_id":2,"store_name":"Click & Collect","provider_name":"Click & Collect","provider_image_full_url" …[truncated]
```

### GET `api/v1/shipping-policy`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/shipping-policy' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":"<h1>sThis is a demo shipping policy<\/h1>\r\n\r\n<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed iaculis nunc tortor, non malesuada nunc tincidunt id. Sed porta ex nec sapien convallis hendrerit. Pellentesque auctor dapibus eleifend. Cras tempus, sapien sed dignissim consequat, dolor nunc volutpat urna, at hendrerit dui dolor dapibus odio. Sed dolor purus, luctus in dui non, fermentum imperdiet nibh. Aenean at libero ut libero auctor finibus. Vivamus eu nulla vel risus dapibus tincidunt eget non orci. Sed lorem velit, sollicitudin eu mi vitae, rutrum congue orci. Phasellus sit amet ex accumsan, semper …[truncated]
```

### GET `api/v1/smart-banners`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/smart-banners' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"title":"Are you hungry?","subtitle":"Explore our food and enjoy.","image_full_url":"{{host}}\/storage\/app\/public\/smart-banner\/2026-06-15-6a2f8a1bc748b.webp","position":"top","redirect_type":"module_home","redirect_target_id":null,"module_id":4}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### GET `api/v1/store-categories`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/store-categories' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":30,"store_id":1,"module_id":1,"name":"Vvhs","slug":"vvhs","image":"2026-06-29-6a418f78c790b.webp","image_full_url":"{{host}}\/storage\/app\/public\/category\/2026-06-29-6a418f78c790b.webp","priority":2,"status":1},{"id":26,"store_id":1,"module_id":1,"name":"Hdhdhfhfhnfcnjf","slug":"hdhdhfhfh","image":"2026-06-29-6a418d23819d0.webp","image_full_url":"{{host}}\/storage\/app\/public\/category\/2026-06-29-6a418d23819d0.webp","priority":2,"status":1},{"id":29,"store_id":1,"module_id":1,"name":"Bxbxxbbxdj","slug":"bxbxxbbxdj","image":"2026-06-29-6a418f4034efe.webp","image_full_url":"{{host}}\/storage\/app\/pu …[truncated]
```

### GET `api/v1/store-categories/items`

- **Auth:** `public`
- **Parameters:** `store_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/store-categories/items?store_id=3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":6,"limit":25,"offset":1,"category_source":"main_category","categories":[{"id":11,"name":"Dairy & Eggs","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-23-6718f111d1be2.png","items_count":2},{"id":53,"name":"Pasta","image_full_url":null,"items_count":1},{"id":47,"name":"Shrimp","image_full_url":null,"items_count":1},{"id":4,"name":"Snacks","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-23-6718f254cb596.png","items_count":1},{"id":134,"name":"Soap","image_full_url":null,"items_count":1}],"category_wise_items":{"11":[{"id":101,"name":"Ferrero Rocher Chocolate Box","s …[truncated]
```

### GET `api/v1/store-categories/store/{storeId}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/store-categories/store/3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":40,"store_id":3,"module_id":1,"name":"Chicken Biryani with Egg","slug":"chicken-biryani-with-egg","image":"2026-07-11-6a51ee218cdbe.webp","image_full_url":"{{host}}\/storage\/app\/public\/category\/2026-07-11-6a51ee218cdbe.webp","priority":0,"status":1}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### GET `api/v1/stores/details/{id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/details/3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":3,"name":"Eorange","slug":"eorange3","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27-671e34990da6e.png","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2024-10-24-671a30c1c05a1.png","module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":6,"items_count":10,"category_ids":[11,9,8,2,5,4,3],"category_names":["Dairy & Eggs","Shrimp","Pasta","Bakery","Gluten-Free"],"delivery_time":"1-1 min","min_delivery_time":1,"max_delivery_time":1,"distance":9772.325650085459,"distance_km":9.77,"open":0,"current_opening_time":"closed","active":0,"free_delivery":0,"is_new":0,"ad …[truncated]
```

### GET `api/v1/stores/discounted`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/discounted' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"name":"Organic Shop","slug":"organic-shop1","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2026-06-21-6a3787aa768d2.webp","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2026-07-11-6a5207c2c04a0.webp","module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":null,"items_count":18,"category_ids":[131,129,157,156,63,1,142,102,104,12],"category_names":["Spices","test testtrye","Wipes","Ghee","Vegetables"],"delivery_time":"10-52 min","min_delivery_time":10,"max_delivery_time":52,"distance":49713.255488951676,"distance_km":49.71,"open":1,"current_opening_time":"06 …[truncated]
```

### GET `api/v1/stores/distance`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/distance' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":12,"name":"Sk General Store","slug":"sk-general-store12","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27-671e344417824.png","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2024-10-24-6719f74230aaf.png","module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":2,"items_count":20,"category_ids":[112,8,9,137,101,47,53,5],"category_names":["Rolls","Seafood","Cleaning","Shrimp","Pasta"],"delivery_time":"2-3 hours","min_delivery_time":2,"max_delivery_time":3,"distance":2830.9568601340025,"distance_km":2.83,"open":1,"current_opening_time":"00:00:00","active": …[truncated]
```

### GET `api/v1/stores/exclusive-deals`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/exclusive-deals' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":14,"name":"Smart Shopping","slug":"smart-shopping14","logo_full_url":null,"cover_photo_full_url":null,"module_id":1,"module_type":"grocery","avg_rating":5,"reviews_count":3,"items_count":0,"category_ids":[62,10,114,8,109,11,108],"category_names":["Chicken","Cookies","Butter","Eggs"],"delivery_time":"2-3 hours","min_delivery_time":2,"max_delivery_time":3,"distance":24740.379145035757,"distance_km":24.74,"open":1,"current_opening_time":"00:00:00","active":1,"free_delivery":0,"is_new":0,"ad":0,"avg_item_discount_percentage":0,"store_discount":{"discount":10,"discount_type":"percent"},"offers":[{"type":"fla …[truncated]
```

### GET `api/v1/stores/get-data`

- **Auth:** `public`
- **Parameters:** `list_type` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/get-data?list_type=item' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":10,"name":"Desi Cow Ghee","slug":"mango-50-gm10","image_full_url":"{{host}}\/storage\/app\/public\/product\/2024-10-27-671e2b0d89830.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2024-10-27-671e2b0d8808e.png","{{host}}\/storage\/app\/public\/product\/2024-10-27-671e2b0d88b69.png"],"price":40,"discount":10,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":286,"unit_type":"Kg","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":3,"rating_count":1,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{ …[truncated]
```

### GET `api/v1/stores/get-stores/{filter_data}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/get-stores/all' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"name":"Organic Shop","slug":"organic-shop1","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2026-06-21-6a3787aa768d2.webp","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2026-07-11-6a5207c2c04a0.webp","module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":6,"items_count":18,"category_ids":[131,129,157,156,63,1,142,102,104,12],"category_names":["Spices","test testtrye","Wipes","Ghee","Vegetables"],"delivery_time":"10-52 min","min_delivery_time":10,"max_delivery_time":52,"distance":49713.255488951676,"distance_km":49.71,"open":1,"current_opening_time":"06:01 …[truncated]
```

### GET `api/v1/stores/latest`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/latest' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":184,"name":"test","slug":"test-vendor-5","logo_full_url":null,"cover_photo_full_url":null,"module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":0,"items_count":2,"category_ids":[],"category_names":[],"delivery_time":"10-23 min","min_delivery_time":10,"max_delivery_time":23,"distance":5090260.4164818665,"distance_km":5090.26,"open":0,"current_opening_time":"closed","active":1,"free_delivery":0,"is_new":0,"ad":0,"avg_item_discount_percentage":0,"store_discount":null,"offers":[],"verified_seller":1},{"id":165,"name":"Test","slug":"test-vendor-3","logo_full_url":null,"cover_photo_full_url":nu …[truncated]
```

### GET `api/v1/stores/popular`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/popular' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":12,"name":"Sk General Store","slug":"sk-general-store12","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27-671e344417824.png","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2024-10-24-6719f74230aaf.png","module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":2,"items_count":20,"category_ids":[112,8,9,137,101,47,53,5],"category_names":["Rolls","Seafood","Cleaning","Shrimp","Pasta"],"delivery_time":"2-3 hours","min_delivery_time":2,"max_delivery_time":3,"distance":2830.9568601340025,"distance_km":2.83,"open":1,"current_opening_time":"00:00:00","active": …[truncated]
```

### GET `api/v1/stores/popular-items/{id}`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/popular-items/3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":101,"name":"Ferrero Rocher Chocolate Box","slug":null,"image_full_url":null,"images_full_url":[null],"price":390,"discount":45,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1879,"unit_type":"Pack","maximum_cart_quantity":0,"veg":0,"organic":0,"is_halal":0,"avg_rating":4,"rating_count":3,"available_time_starts":"00:00:00","available_time_ends":"23:59:00","brand_name":null,"category_ids":[{"id":"11","position":1}],"module_id":1,"module_type":"grocery","store_id":3,"store_name":"Eorange","store_slug":"eorange3","store_image_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27- …[truncated]
```

### GET `api/v1/stores/quick-delivery`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/quick-delivery' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"name":"Organic Shop","slug":"organic-shop1","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2026-06-21-6a3787aa768d2.webp","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2026-07-11-6a5207c2c04a0.webp","module_id":1,"module_type":"grocery","avg_rating":3.8333,"reviews_count":6,"items_count":18,"category_ids":[131,129,157,156,63,1,142,102,104,12],"category_names":["Spices","test testtrye","Wipes","Ghee","Vegetables"],"delivery_time":"10-52 min","min_delivery_time":10,"max_delivery_time":52,"distance":49713.255488951676,"distance_km":49.71,"open":1,"current_opening_time":" …[truncated]
```

### GET `api/v1/stores/recommended`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/recommended' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":5,"name":"Family supermarket","slug":"family-supermarket5","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27-671e348a5fec5.png","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2024-10-24-6719eb89a3c78.png","module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":0,"items_count":5,"category_ids":[53,5,140,102,103,12,50,3,51],"category_names":["Pasta","Oils","Fruits","Gluten-Free","Organic Foods"],"delivery_time":"2-3 hours","min_delivery_time":2,"max_delivery_time":3,"distance":4352100.344589512,"distance_km":4352.1,"open":1,"current_opening_time":"00:00 …[truncated]
```

### GET `api/v1/stores/reviews`

- **Auth:** `public`
- **Parameters:** `store_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/reviews?store_id=3' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":33,"item_id":117,"user_id":280,"comment":"o","attachment":[],"rating":1,"order_id":102246,"created_at":"2026-03-24T09:42:52.000000Z","updated_at":"2026-03-24T09:42:52.000000Z","item_campaign_id":null,"status":1,"module_id":1,"store_id":null,"reply":null,"review_id":"102246","replied_at":null,"item_name":"Heinz Tomato Ketchup","item_image":"2022-03-22-6239d3bfc2275.png","customer_name":"Romjan User","item_image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d3bfc2275.png","item":{"id":117,"name":"Heinz Tomato Ketchup","slug":null,"image_full_url":"{{host}}\/storage\/app\/public\/produ …[truncated]
```

### GET `api/v1/stores/search`

- **Auth:** `public`
- **Parameters:** `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/search?name=Organic' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"name":"Organic Shop","slug":"organic-shop1","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2026-06-21-6a3787aa768d2.webp","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2026-07-11-6a5207c2c04a0.webp","module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":null,"items_count":18,"category_ids":[131,129,157,156,63,1,142,102,104,12],"category_names":["Spices","test testtrye","Wipes","Ghee","Vegetables"],"delivery_time":"10-52 min","min_delivery_time":10,"max_delivery_time":52,"distance":49713.255488951676,"distance_km":49.71,"open":1,"current_opening_time":"06 …[truncated]
```

### GET `api/v1/stores/top-offer-near-me`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/top-offer-near-me' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":14,"name":"Smart Shopping","slug":"smart-shopping14","logo_full_url":null,"cover_photo_full_url":null,"module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":3,"items_count":5,"category_ids":[62,10,114,8,109,11,108],"category_names":["Chicken","Cookies","Butter","Eggs"],"delivery_time":"2-3 hours","min_delivery_time":2,"max_delivery_time":3,"distance":24740.379145035757,"distance_km":24.74,"open":1,"current_opening_time":"00:00:00","active":1,"free_delivery":0,"is_new":0,"ad":0,"avg_item_discount_percentage":0,"store_discount":{"discount":10,"discount_type":"percent"},"offers":[{"type":"fla …[truncated]
```

### GET `api/v1/stores/top-rated`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/top-rated' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"name":"Organic Shop","slug":"organic-shop1","logo_full_url":"{{host}}\/storage\/app\/public\/store\/2026-06-21-6a3787aa768d2.webp","cover_photo_full_url":"{{host}}\/storage\/app\/public\/store\/cover\/2026-07-11-6a5207c2c04a0.webp","module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":null,"items_count":18,"category_ids":[131,129,157,156,63,1,142,102,104,12],"category_names":["Spices","test testtrye","Wipes","Ghee","Vegetables"],"delivery_time":"10-52 min","min_delivery_time":10,"max_delivery_time":52,"distance":49713.255488951676,"distance_km":49.71,"open":1,"current_opening_time":"06 …[truncated]
```

### GET `api/v1/stores/verified`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/stores/verified' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":121,"name":"afasdf sdfafas","slug":"afasdf-sdfafas","logo_full_url":null,"cover_photo_full_url":null,"module_id":1,"module_type":"grocery","avg_rating":0,"reviews_count":0,"items_count":0,"category_ids":[],"category_names":[],"delivery_time":"23-23 min","min_delivery_time":23,"max_delivery_time":23,"distance":7740.788260592351,"distance_km":7.74,"open":0,"current_opening_time":"closed","active":1,"free_delivery":0,"is_new":0,"ad":0,"avg_item_discount_percentage":0,"store_discount":null,"offers":[],"verified_seller":1},{"id":118,"name":"dsfgs","slug":"dsfgs","logo_full_url":null,"cover_photo_full_url":nu …[truncated]
```

### PUT `api/v1/taxvat/get-calculated-tax`

- **Auth:** `public`
- **Parameters:** `totalProductAmount` (**required**), `productIds` (**required**), `categoryIds` (**required**), `quantity` (**required**), `additionalCharges` (optional), `orderId` (optional), `countryCode` (optional), `taxPayer` (optional), `addonIds` (optional), `addonQuantity` (optional), `addonCategoryIds` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/taxvat/get-calculated-tax' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"totalProductAmount":"test","productIds":"test","categoryIds":"test","quantity":1,"additionalCharges":"test","orderId":"test","countryCode":"test","taxPayer":"test","addonIds":"test","addonQuantity":"test","addonCategoryIds":"test"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The total product amount must be a number.","content":null,"errors":{"totalProductAmount":["The total product amount must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/taxvat/get-taxVat-list`

- **Auth:** `public`
- **Parameters:** `limit` (optional), `offset` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/taxvat/get-taxVat-list?limit=10&offset=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":6,"name":"asd","tax_rate":0},{"id":5,"name":"Text TAX","tax_rate":20},{"id":3,"name":"Custom Tax","tax_rate":90},{"id":2,"name":"Service tax2333","tax_rate":0.05},{"id":1,"name":"GST","tax_rate":50}],"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":5,"from":1,"to":5}},"errors":[]}
```

### GET `api/v1/terms-and-conditions`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/terms-and-conditions' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":"<h1>sThis is a test Teams &amp; Conditionss<\/h1>\r\n\r\n<p>These terms of use (the &quot;Terms of Use&quot;) govern your use of our website www.6ammart,6amtech.com (the &quot;Website&quot;) and our &quot;6amMart&quot; application for mobile and handheld devices (the &quot;App&quot;). The Website and the App are jointly referred to as the &quot;Platform&quot;. Please read these Terms of Use carefully before you use the services. If you do not agree to these Terms of Use, you may not use the services on the Platform, and we request you to uninstall the App. By installing, downloading and\/or even merely using the Plat …[truncated]
```

### GET `api/v1/trending-searches`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/trending-searches?name=Ferrero' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"trending_searches":[{"keyword":"Snacks","module_id":1},{"keyword":"Bakery","module_id":1},{"keyword":"Meat","module_id":1},{"keyword":"Personal Care","module_id":1},{"keyword":"Pantry","module_id":1},{"keyword":"Seafood","module_id":1},{"keyword":"Pharma","module_id":1},{"keyword":"Frozen","module_id":1},{"keyword":"Dairy & Eggs","module_id":1},{"keyword":"Beverages","module_id":1}]},"errors":[]}
```

### GET `api/v1/vehicle/extra_charge`

- **Auth:** `public`
- **Parameters:** `distance` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vehicle/extra_charge?distance=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":50,"errors":[]}
```

### GET `api/v1/vendor/addon`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/addon' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":90,"name":"Cheese","price":10,"created_at":"2026-08-27T07:53:20.000000Z","updated_at":"2026-08-27T07:53:20.000000Z","store_id":3,"status":1,"addon_category_id":null,"tax_ids":[],"translations":[]}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### DELETE `api/v1/vendor/addon/delete`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/addon/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/addon/status`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/addon/status?id=1&status=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/addon/store`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**), `addon_category_id` (**required**), `price` (**required**), `translations` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/addon/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"name":"Audit Probe","addon_category_id":1,"price":100,"translations":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Name and description in english is required","content":null,"errors":{"translations":["Name and description in english is required"]}}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/vendor/addon/update`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**), `addon_category_id` (**required**), `price` (**required**), `translations` (**required**), `id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/addon/update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"name":"Audit Probe","addon_category_id":1,"price":100,"translations":[],"id":1}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Name and description in english is required","content":null,"errors":{"translations":["Name and description in english is required"]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/advertisement`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/advertisement' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1000019,"add_type":"store_promotion","title":"Get Rewarded Instantly","description":"Get also discount","start_date":"2026-06-21","end_date":"2026-06-21","status":"approved","active":0,"priority":4,"pause_note":null,"cancellation_note":null,"is_rating_active":1,"is_review_active":1,"is_paid":1,"is_updated":0,"cover_image_full_url":"{{host}}\/storage\/app\/public\/advertisement\/2026-06-21-6a3791080ab79.webp","profile_image_full_url":"{{host}}\/storage\/app\/public\/advertisement\/2026-06-21-6a3791080c236.webp","video_attachment_full_url":null,"created_at":"2025-11-05T10:42:59.000000Z","translations":[{" …[truncated]
```

### POST `api/v1/vendor/advertisement/copy-add-post`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `title` (optional), `description` (optional), `dates` (**required**), `advertisement_type` (**required**), `cover_image` (optional), `profile_image` (optional), `video_attachment` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/advertisement/copy-add-post' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1,"title":"Audit Probe","description":"Audit probe description","dates":"2026-08-27","advertisement_type":"video_promotion"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The dates format is invalid.","content":null,"errors":{"dates":["The dates format is invalid."],"translations":["Title and description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `cover_image`, `profile_image`, `video_attachment` — send as `multipart/form-data`.*

### DELETE `api/v1/vendor/advertisement/delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/advertisement/delete/1000000' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/advertisement/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/advertisement/details/1000000' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### PUT `api/v1/vendor/advertisement/status`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `status` (**required**), `pause_note` (conditional — `required_if:status,paused`), `cancellation_note` (conditional — `required_if:status,denied`)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/advertisement/status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1,"status":"paused","pause_note":"test","cancellation_note":"test"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/advertisement/store`

- **Auth:** `vendor`
- **Parameters:** `title` (optional), `description` (optional), `dates` (**required**), `advertisement_type` (**required**), `cover_image` (conditional — `required_if:advertisement_type,store_promotion`), `profile_image` (conditional — `required_if:advertisement_type,store_promotion`), `video_attachment` (conditional — `required_if:advertisement_type,video_promotion`)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/advertisement/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"title":"Audit Probe","description":"Audit probe description","dates":"2026-08-27","advertisement_type":"video_promotion"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The dates format is invalid.","content":null,"errors":{"dates":["The dates format is invalid."],"video_attachment":["Your video attachment is missing"],"translations":["Title and description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `cover_image`, `profile_image`, `video_attachment` — send as `multipart/form-data`.*

### POST `api/v1/vendor/advertisement/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `title` (optional), `description` (optional), `dates` (**required**), `advertisement_type` (**required**), `cover_image` (optional), `profile_image` (optional), `video_attachment` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/advertisement/update/1000000' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1,"title":"Audit Probe","description":"Audit probe description","dates":"2026-08-27","advertisement_type":"video_promotion"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The dates format is invalid.","content":null,"errors":{"dates":["The dates format is invalid."],"translations":["Title and description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `cover_image`, `profile_image`, `video_attachment` — send as `multipart/form-data`.*

### GET `api/v1/vendor/all-orders`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/all-orders' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":103022,"user_id":2,"order_amount":321,"coupon_discount_amount":0,"coupon_discount_title":null,"payment_status":"unpaid","order_status":"pending","total_tax_amount":0,"payment_method":"cash_on_delivery","transaction_reference":null,"delivery_address_id":null,"delivery_man_id":null,"coupon_code":null,"order_note":null,"order_type":"delivery","checked":1,"store_id":3,"created_at":"2026-08-20 15:20:51","updated_at":"2026-08-20T09:22:26.000000Z","delivery_charge":150,"delivery_type":"standard","delivery_type_charge":0,"schedule_at":"2026-08-20 15:20:51","callback":null,"otp":"4548","pending":null,"accepted": …[truncated]
```

### GET `api/v1/vendor/attributes`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/attributes' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":5,"name":"aTTRIBUTE TYPE","created_at":"2025-11-06T13:10:13.000000Z","updated_at":"2025-11-06T13:10:13.000000Z","translations":[{"id":3190,"translationable_type":"App\\Models\\Attribute","translationable_id":5,"locale":"en","key":"name","value":"aTTRIBUTE TYPE","created_at":null,"updated_at":null}]},{"id":2,"name":"Colorz","created_at":"2022-03-22T16:47:26.000000Z","updated_at":"2025-10-07T12:35:39.000000Z","translations":[{"id":2962,"translationable_type":"App\\Models\\Attribute","translationable_id":2,"locale":"en","key":"name","value":"Colorz","created_at":null,"updated_at":null}]},{"id":6,"name":"ph …[truncated]
```

### GET `api/v1/vendor/banner`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/banner' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### DELETE `api/v1/vendor/banner/delete`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/banner/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/banner/edit/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/banner/edit/7' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/banner/status`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/banner/status?id=1&status=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/banner/store`

- **Auth:** `vendor`
- **Parameters:** `image` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/banner/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Image is required","content":null,"errors":{"image":["Image is required"],"translations":["Title and description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### PUT `api/v1/vendor/banner/update`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `image` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/banner/update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Title and description in english is required","content":null,"errors":{"translations":["Title and description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### POST `api/v1/vendor/booking/assign-serviceman/{id}`

- **Auth:** `vendor`
- **Parameters:** `serviceman_ids` (optional), `serviceman_ids.*` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/booking/assign-serviceman/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"serviceman_ids":[]}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"message":"Serviceman updated successfully","servicemen":[]},"errors":[]}
```

### GET `api/v1/vendor/booking/assignable-servicemen/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/booking/assignable-servicemen/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":2,"servicemen":[{"id":9,"name":"Audit Probe","phone":"+8801700000903","image_full_url":null,"is_assigned":false,"conflict_count":0},{"id":23,"name":"Seed Serviceman Two","phone":"+8801700000904","image_full_url":null,"is_assigned":false,"conflict_count":0}]},"errors":[]}
```

### GET `api/v1/vendor/booking/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/booking/details/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":102691,"display_id":"SVCSEED-100","booking_type":"regular","multi_booking_type":null,"parent_booking_id":null,"is_repeat_parent":false,"child_bookings_count":0,"is_custom":false,"is_campaign":false,"can_rebook":false,"provider_can_cancel":false,"booking_status":"pending","status_label":"Pending","status_history":null,"status_histories":[],"payment_status":"unpaid","payment_method":"cash_on_delivery","transaction_reference":null,"scheduled":0,"schedule_at":"2026-08-26 15:25:13","quantity":1,"booking_note":null,"bring_change_amount":0,"attachments":[],"completion_evidence":[],"cancellation_reason":null,"canceled_b …[truncated]
```

### GET `api/v1/vendor/booking/edit-catalog/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/booking/edit-catalog/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"is_editable":false,"reason":"Booking edit is disabled","lines":[],"catalog":[]},"errors":[]}
```

### POST `api/v1/vendor/booking/edit-preview/{id}`

- **Auth:** `vendor`
- **Parameters:** `lines` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/booking/edit-preview/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"lines":"test"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"booking","message":"Booking edit is disabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/booking/edit-update/{id}`

- **Auth:** `vendor`
- **Parameters:** `lines` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/booking/edit-update/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"lines":"test"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"booking","message":"Booking edit is disabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/booking/invoice/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/booking/invoice/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
%PDF-1.4 %???? 3 0 obj <</Type /Page /Parent 1 0 R /MediaBox [0 0 538.583 708.661] /TrimBox [0.000 0.000 538.583 708.661] /Resources 2 0 R /Group << /Type /Group /S /Transparency /CS /DeviceRGB >> /Contents 4 0 R>> endobj 4 0 obj <</Filter /FlateDecode /Length 1864>> stream x??Y[o7??? K?P????*TH(???R??!MB?$YH????3??%??l@}A??Y{??򝫽??әV>D?q?pW???Ȥ?k??R>??+??|<3?y4??x?ȣ??;?????򠽓?wR?2ߣ?{r??h朊QK??$-??;d??C?R>?jm?*?֚T?y?b?YiOm?'<????ZeLl?A??4r?3N???,???_p??3Ic#?=?4 ??d?%?dr^(2??)o?'?T|s?Z????????{g?^$t9y땉?#???? ȟ?#!?-?#~[??µ-?#?? ?c??WԸl?=q!?=p ?A??x~w0???ka?߾' ~?????._?~u??iTb?????w??=?? y'"* ?(?r?D?'?W?Ϡ?ōlAɪ? ?LF??o??#????.0??? …[truncated]
```

### GET `api/v1/vendor/booking/list`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional), `status` (optional), `search` (optional), `scheduled` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/booking/list?limit=10&offset=1&status=1&search=test&scheduled=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":0,"limit":10,"offset":1,"bookings":[]},"errors":[]}
```

### GET `api/v1/vendor/booking/log/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/booking/log/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"booking","message":"Service log is only available for repeat bookings"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/booking/reschedule/{id}`

- **Auth:** `vendor`
- **Parameters:** `service_schedule` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/booking/reschedule/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"service_schedule":"2026-08-27"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The service schedule must be a date after now.","content":null,"errors":{"service_schedule":["The service schedule must be a date after now."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/booking/send-otp/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/booking/send-otp/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"otp","message":"Otp verification is not enabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/booking/status/{id}`

- **Auth:** `vendor`
- **Parameters:** `booking_status` (**required**), `cancellation_reason` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/booking/status/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"booking_status":"test","cancellation_reason":"test"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"booking_status","message":"Invalid status"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/booking/update-location/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/booking/update-location/102691' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"booking","message":"Booking edit is disabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/business_plan`

- **Auth:** `public`
- **Parameters:** `store_id` (**required**), `payment` (optional), `business_plan` (**required**), `package_id` (conditional — `required_if:business_plan,subscription`), `payment_gateway` (conditional — `required_if:business_plan,subscription`), `payment_platform` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/business_plan' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"store_id":3,"payment":"test","business_plan":"subscription","package_id":1,"payment_gateway":"test","payment_platform":"app"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### PUT `api/v1/vendor/campaign-join`

- **Auth:** `vendor`
- **Parameters:** `campaign_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/campaign-join' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"campaign_id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Campaign not found or upavailable!","content":null,"errors":[{"code":"campaign","message":"Campaign not found or upavailable!"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### PUT `api/v1/vendor/campaign-leave`

- **Auth:** `vendor`
- **Parameters:** `campaign_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/campaign-leave' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"campaign_id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Campaign not found or upavailable!","content":null,"errors":[{"code":"campaign","message":"Campaign not found or upavailable!"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/cancel-subscription`

- **Auth:** `public`
- **Parameters:** `store_id` (**required**), `subscription_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/cancel-subscription' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -d '{"store_id":3,"subscription_id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/canceled-orders`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/canceled-orders' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":102807,"user_id":8,"order_amount":841.2,"coupon_discount_amount":0,"coupon_discount_title":"","payment_status":"unpaid","order_status":"canceled","total_tax_amount":0,"payment_method":"offline_payment","transaction_reference":null,"delivery_address_id":null,"delivery_man_id":null,"coupon_code":null,"order_note":null,"order_type":"delivery","checked":1,"store_id":3,"created_at":"2026-06-28 01:07:38","updated_at":"2026-07-05T15:56:38.000000Z","delivery_charge":600,"delivery_type":"standard","delivery_type_charge":0,"schedule_at":"2026-06-28 01:07:38","callback":"http:\/\/localhost:3003\/profile?page=my-or …[truncated]
```

### GET `api/v1/vendor/categories`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/categories' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":2,"name":"Personal Care","slug":"seafood2","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-24-6719c71a0338d.png","parent_id":0,"priority":2,"featured":0,"products_count":1,"childs_count":4},{"id":4,"name":"Snacks","slug":"snacks4","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-23-6718f254cb596.png","parent_id":0,"priority":2,"featured":0,"products_count":1,"childs_count":4},{"id":5,"name":"Pantry","slug":"pantry5","image_full_url":"{{host}}\/storage\/app\/public\/category\/2024-10-23-6718f227a2627.png","parent_id":0,"priority":2,"featured":0,"products_count":1,"c …[truncated]
```

### GET `api/v1/vendor/categories/category-wise-products/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/categories/category-wise-products/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":115,"name":"Praise Daily Style Mayonnaise","slug":"praise-daily-style-mayonnaise115","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b964484.png","images_full_url":["{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d2b963233.png"],"price":230,"discount":30,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":1996,"unit_type":"Ltr","maximum_cart_quantity":null,"veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"2","position":1},{"id":" …[truncated]
```

### GET `api/v1/vendor/categories/childes/{category_id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/categories/childes/2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":133,"name":"Shampoo","slug":"shampoo","image_full_url":null,"parent_id":2,"priority":0,"featured":0,"products_count":0,"childs_count":0},{"id":134,"name":"Soap","slug":"soap","image_full_url":null,"parent_id":2,"priority":0,"featured":0,"products_count":1,"childs_count":0},{"id":135,"name":"Skincare","slug":"skincare","image_full_url":null,"parent_id":2,"priority":0,"featured":0,"products_count":0,"childs_count":0},{"id":136,"name":"Oral Care","slug":"oral-care","image_full_url":null,"parent_id":2,"priority":0,"featured":0,"products_count":0,"childs_count":0}],"pagination":{"current_page":1,"last_page": …[truncated]
```

### GET `api/v1/vendor/check-product-limits`

- **Auth:** `public`
- **Parameters:** `store_id` (**required**), `package_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/check-product-limits?store_id=3&package_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/completed-orders`

- **Auth:** `vendor`
- **Parameters:** `status` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/completed-orders?status=all' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":102948,"user_id":280,"order_amount":854.98,"coupon_discount_amount":0,"coupon_discount_title":"","payment_status":"paid","order_status":"delivered","total_tax_amount":115.83,"payment_method":"cash_on_delivery","transaction_reference":null,"delivery_address_id":null,"delivery_man_id":null,"coupon_code":null,"order_note":null,"order_type":"delivery","checked":1,"store_id":3,"created_at":"2026-07-14 16:10:18","updated_at":"2026-07-14T10:11:20.000000Z","delivery_charge":150,"delivery_type":"standard","delivery_type_charge":0,"schedule_at":"2026-07-14 16:10:18","callback":null,"otp":"3371","pending":"2026-07 …[truncated]
```

### POST `api/v1/vendor/coupon/delete`

- **Auth:** `vendor`
- **Parameters:** `coupon_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/coupon/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"coupon_id":461}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":null,"errors":[]}
```

### GET `api/v1/vendor/coupon/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/coupon/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":461,"title":"Super offer (30%)","code":"AUDITFIXTURE","start_date":"2026-07-27","expire_date":"2027-08-27","min_purchase":0,"max_discount":0,"discount":30,"discount_type":"percent","coupon_type":"store_wise","limit":2,"status":1,"total_uses":0,"created_at":"2026-08-27T08:12:54.000000Z","data":["1"],"customer_id":["all"],"translations":[]}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### POST `api/v1/vendor/coupon/search`

- **Auth:** `vendor`
- **Parameters:** `search` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/coupon/search' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"search":"Ferrero"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### POST `api/v1/vendor/coupon/status`

- **Auth:** `vendor`
- **Parameters:** `coupon_id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/coupon/status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"coupon_id":461,"status":1}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Successfully updated","content":null,"errors":[]}
```

### POST `api/v1/vendor/coupon/store`

- **Auth:** `vendor`
- **Parameters:** `code` (**required**), `start_date` (**required**), `expire_date` (**required**), `coupon_type` (**required**), `discount` (conditional — `required_if:coupon_type,default`), `max_discount` (**required**), `translations` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/coupon/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"code":"bogo","start_date":"2026-08-27","expire_date":"2026-08-27","coupon_type":"free_delivery","discount":1,"max_discount":"test","translations":"test"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The code has already been taken.","content":null,"errors":{"code":["The code has already been taken."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/coupon/update`

- **Auth:** `vendor`
- **Parameters:** `code` (**required**), `start_date` (**required**), `expire_date` (**required**), `coupon_type` (**required**), `discount` (conditional — `required_if:coupon_type,default`), `max_discount` (**required**), `translations` (**required**), `coupon_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/coupon/update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"code":"bogo","start_date":"2026-08-27","expire_date":"2026-08-27","coupon_type":"free_delivery","discount":1,"max_discount":"test","translations":"test","coupon_id":461}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The code has already been taken.","content":null,"errors":{"code":["The code has already been taken."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/coupon/view`

- **Auth:** `vendor`
- **Parameters:** `coupon_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/coupon/view?coupon_id=461' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":461,"title":"Super offer (30%)","code":"AUDITFIXTURE","start_date":"2026-07-27","expire_date":"2027-08-27","min_purchase":0,"max_discount":0,"discount":30,"discount_type":"percent","coupon_type":"store_wise","limit":2,"status":1,"total_uses":0,"created_at":"2026-08-27T08:12:54.000000Z","data":["1"],"customer_id":["all"],"translations":[]},"errors":[]}
```

### GET `api/v1/vendor/coupon/view-without-translate`

- **Auth:** `vendor`
- **Parameters:** `coupon_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/coupon/view-without-translate?coupon_id=461' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":461,"title":"Super offer (30%)","code":"AUDITFIXTURE","start_date":"2026-07-27","expire_date":"2027-08-27","min_purchase":0,"max_discount":0,"discount":30,"discount_type":"percent","coupon_type":"store_wise","limit":2,"status":1,"total_uses":0,"created_at":"2026-08-27T08:12:54.000000Z","data":["1"],"customer_id":["all"],"translations":[]},"errors":[]}
```

### GET `api/v1/vendor/current-orders`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/current-orders' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":103022,"user_id":2,"order_amount":321,"coupon_discount_amount":0,"coupon_discount_title":null,"payment_status":"unpaid","order_status":"pending","total_tax_amount":0,"payment_method":"cash_on_delivery","transaction_reference":null,"delivery_address_id":null,"delivery_man_id":null,"coupon_code":null,"order_note":null,"order_type":"delivery","checked":1,"store_id":3,"created_at":"2026-08-20 15:20:51","updated_at":"2026-08-20T09:22:26.000000Z","delivery_charge":150,"delivery_type":"standard","delivery_type_charge":0,"schedule_at":"2026-08-20 15:20:51","callback":null,"otp":"4548","pending":null,"accepted": …[truncated]
```

### DELETE `api/v1/vendor/delivery-man/delete`

- **Auth:** `vendor`
- **Parameters:** `delivery_man_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/delivery-man/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"delivery_man_id":1}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"unauthorized","message":"Permission denied"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/delivery-man/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/delivery-man/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"unauthorized","message":"Permission denied"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/delivery-man/preview`

- **Auth:** `vendor`
- **Parameters:** `delivery_man_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/delivery-man/preview?delivery_man_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"unauthorized","message":"Permission denied"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/delivery-man/search`

- **Auth:** `vendor`
- **Parameters:** `search` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/delivery-man/search' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"search":"Ferrero"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"unauthorized","message":"Permission denied"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/delivery-man/status`

- **Auth:** `vendor`
- **Parameters:** `delivery_man_id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/delivery-man/status?delivery_man_id=1&status=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"unauthorized","message":"Permission denied"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/delivery-man/store`

- **Auth:** `vendor`
- **Parameters:** `f_name` (**required**), `identity_type` (**required**), `identity_number` (**required**), `email` (**required**), `phone` (**required**), `password` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/delivery-man/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"f_name":"Audit","identity_type":"passport","identity_number":"test","email":"audit239375a2@example.com","phone":"+880945092791","password":"Str0ng@Pass1"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"unauthorized","message":"Permission denied"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/delivery-man/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `f_name` (**required**), `email` (**required**), `phone` (**required**), `password` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/delivery-man/update/7' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"f_name":"Audit","email":"grocery.store2@demo.com","phone":"02000000002","password":"Str0ng@Pass1"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"unauthorized","message":"Permission denied"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/earning-info`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/earning-info' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"monthely_earning":0,"weekly_earning":0,"daily_earning":0},"errors":[]}
```

### GET `api/v1/vendor/earning-report`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/earning-report' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"summary":{"total_earnings_with_admin_commission":30878.71,"total_earnings_percentage":100,"total_earnings_positive":true,"total_expenses":8125.5,"total_expenses_percentage":100,"total_expenses_positive":true,"net_profit":22753.21,"net_profit_percentage":100,"net_profit_positive":true,"total_transaction_earning_count":22,"total_transaction_expense_count":49,"total_transaction_subscription_count":1,"breakdown":{"order_sales":24738.1,"order_sales_percentage":93.7,"order_sales_positive":true,"tax_collected":"1642.71","tax_collected_percentage":6.22,"tax_collected_positive":true,"packaging_fee_collected":20,"packaging_fe …[truncated]
```

### GET `api/v1/vendor/get-basic-campaigns`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/get-basic-campaigns' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":20,"title":"Offer Offer Offer Offer Offer Offer","image":"2026-06-22-6a38cdce2e51c.webp","description":"Offer Offer Offer Offer Offer Offer","status":1,"admin_id":null,"created_at":"2026-03-29T15:03:01.000000Z","updated_at":"2026-06-22T11:53:18.000000Z","start_time":"09:02","end_time":"22:02","module_id":1,"slug":"offer-offer-offer-offer-offer-offer","available_date_starts":"2026-06-22","available_date_ends":"2027-10-02","vendor_status":"confirmed","is_joined":true,"image_full_url":"{{host}}\/storage\/app\/public\/campaign\/2026-06-22-6a38cdce2e51c.webp","storage":[{"id":2062,"data_type":"App\\Models\\C …[truncated]
```

### GET `api/v1/vendor/get-disbursement-report`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/get-disbursement-report' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"pending":19067.71,"completed":0,"canceled":0,"complete_day":2,"data":[{"id":26,"disbursement_id":1020,"store_id":3,"delivery_man_id":null,"disbursement_amount":1261.26,"payment_method":23,"status":"pending","created_at":"2026-07-27T13:34:06.000000Z","updated_at":"2026-07-27T13:34:06.000000Z","store":{"id":3,"name":"Eorange","phone":"02000000002","email":"grocery.store2@demo.com","logo":"2024-10-27-671e34990da6e.png","latitude":"23.805438526268976","longitude":"90.36799765290114","address":"House: 00, Road: 00, City-000, Country","footer_text":null,"minimum_order":1,"comission":20,"schedule_order":true,"status":1,"ve …[truncated]
```

### GET `api/v1/vendor/get-expense`

- **Auth:** `vendor`
- **Parameters:** `from` (**required**), `to` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/get-expense?from=2026-08-27&to=2026-08-27' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":16162,"type":"flash_sale_discount","amount":7.8,"order_id":100105,"created_at":"2026-08-27 13:53:20","updated_at":"2026-08-27T07:53:20.000000Z","description":"","created_by":"vendor","store_id":3,"delivery_man_id":null,"user_id":null,"trip_id":null,"ride_id":null,"service_booking_id":null}],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1,"from":1,"to":1}},"errors":[]}
```

### GET `api/v1/vendor/get-items-list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/get-items-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":402,"name":"Fresh Flavor Dhaka Essentials","description":"Discover the vibrant taste of \"Fresh Flavor Dhaka Essentials,\" a gourmet blend that brings the authentic flavors of Dhaka to your kitchen. Each pack is filled with the freshest ingredients, including aromatic spices and herbs, ensuring a burst of flavor in every dish. Perfect for creating traditional Bangladeshi cuisine or adding a unique twist to your favorite recipes. Enjoy the convenience of premium quality and freshness, carefully sealed to preserve its rich taste. Elevate your culinary experience with this essential pantry staple, crafted  …[truncated]
```

### GET `api/v1/vendor/get-searched-food`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/get-searched-food?name=Ferrero' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":101,"name":"Ferrero Rocher Chocolate Box","image":null,"formatted_price":"214.500 \u09f3","original_price":"390.000 \u09f3","has_variations":false,"has_addons":false,"is_available":true,"available_time":null,"tracks_stock":true,"stock":1879,"veg":null,"is_halal":false},{"id":106,"name":"Blue Grapes","image":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d029d1dc8.png","formatted_price":"200.000 \u09f3","original_price":null,"has_variations":false,"has_addons":false,"is_available":true,"available_time":null,"tracks_stock":true,"stock":927,"veg":null,"is_halal":false},{"id":115,"name":"Praise Da …[truncated]
```

### GET `api/v1/vendor/get-tax-report`

- **Auth:** `vendor`
- **Parameters:** `from` (**required**), `to` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/get-tax-report?from=2026-08-27&to=2026-08-27' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The from does not match the format m\/d\/Y.","content":null,"errors":{"from":["The from does not match the format m\/d\/Y."],"to":["The to does not match the format m\/d\/Y."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/get-withdraw-list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/get-withdraw-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":73,"vendor_id":3,"admin_id":null,"transaction_note":"Store_wallet_adjustment_full","amount":100,"updated_at":"2026-08-20T07:22:53.000000Z","delivery_man_id":null,"withdrawal_method_id":null,"withdrawal_method_fields":null,"type":"adjustment","sender_note":null,"user_note":null,"status":"Approved","requested_at":"2026-08-20 13:22:53","bank_name":"Account","detail":null,"method":null,"disbursement_method":null},{"id":5,"vendor_id":3,"admin_id":null,"transaction_note":null,"amount":3500,"updated_at":"2022-09-29T15:14:26.000000Z","delivery_man_id":null,"withdrawal_method_id":null,"withdrawal_method_fields": …[truncated]
```

### GET `api/v1/vendor/get-withdraw-method-list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/get-withdraw-method-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"method_name":"Card","method_fields":[{"input_type":"string","input_name":"account_name","placeholder":"Enter your card holder name","is_required":1},{"input_type":"number","input_name":"account_number","placeholder":"Enter your account number","is_required":1},{"input_type":"email","input_name":"email","placeholder":"Enter your account email","is_required":0}],"is_default":1,"is_active":1,"created_at":"2023-11-27T12:22:06.000000Z","updated_at":"2023-11-27T12:22:06.000000Z"},{"id":2,"method_name":"6cash","method_fields":[{"input_type":"string","input_name":"account_name","placeholder":"Enter your acco …[truncated]
```

### DELETE `api/v1/vendor/item/delete`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/item/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/item/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/item/details/101' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":101,"name":"\u0639\u0644\u0628\u0629 \u0634\u0648\u0643\u0648\u0644\u0627\u062a\u0629 \u0641\u064a\u0631\u064a\u0631\u0648 \u0631\u0648\u0634\u064a\u0647","description":"4 \u062d\u0644\u0648\u0649 \u0634\u0648\u0643\u0648\u0644\u0627\u062a\u0629 \u0641\u064a\u0631\u064a\u0631\u0648 \u0631\u0648\u0634\u064a\u0647 \u0644\u0630\u064a\u0630\u0629 \u060c \u0645\u0642\u062f\u0645\u0629 \u0641\u064a \u0635\u0646\u062f\u0648\u0642 \u0647\u062f\u0627\u064a\u0627 \u0634\u0641\u0627\u0641 \u0645\u062b\u064a\u0631 \u0644\u0644\u0625\u0639\u062c\u0627\u0628 \u060c \u0647\u062f\u064a\u0629 \u0639\u064a\u062f \u0627\u0644\u062 …[truncated]
```

### GET `api/v1/vendor/item/organic`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `organic` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/item/organic?id=1&organic=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/item/pending/item/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/item/pending/item/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":268,"name":"Lung Exerciser","image":"2025-06-26-685cce8a55259.png","price":50,"is_rejected":1,"item_id":84,"category_ids":[{"id":"19","position":1,"name":"Devices"}],"video":null,"video_link":null,"image_full_url":null,"images_full_url":[],"video_full_url":null,"video_size":0,"video_preview_type":null,"video_embed_url":null,"video_preview_url":null,"video_thumbnail_url":"{{host}}\/public\/assets\/admin\/img\/video-placeholder.svg","video_preview_modal_type":null,"video_preview_modal_url":null,"has_video_preview":false,"has_video_source":false,"store_category":null,"storage":[]}],"pagination":{"current_p …[truncated]
```

### GET `api/v1/vendor/item/recommended`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/item/recommended?id=1&status=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### PUT `api/v1/vendor/item/reply-update`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `reply` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/item/reply-update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1,"reply":"test"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/item/requested/item/view/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/item/requested/item/view/101' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/item/reviews`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/item/reviews' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":33,"item_id":117,"user_id":280,"comment":"o","attachment":[],"rating":1,"order_id":102246,"created_at":"2026-03-24T09:42:52.000000Z","updated_at":"2026-03-24T09:42:52.000000Z","item_campaign_id":null,"status":1,"module_id":1,"store_id":null,"reply":null,"review_id":"102246","replied_at":null,"item_name":"Heinz Tomato Ketchup","item_image":"2022-03-22-6239d3bfc2275.png","customer_name":"Romjan User","item_image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d3bfc2275.png"},{"id":32,"item_id":117,"user_id":280,"comment":"nice-","attachment":[],"rating":3,"order_id":102242,"created_at": …[truncated]
```

### POST `api/v1/vendor/item/search`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/item/search' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"name":"Ferrero"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":101,"name":"Ferrero Rocher Chocolate Box","description":"4 delicious Ferrero Rocher chocolate candies, presented in an impressive transparent gift box, the perfect Valentine's Day or Chinese New Year gift for him or her","image":"2022-03-22-6239ceff780fd.png","video":null,"video_link":null,"category_id":11,"category_ids":[{"id":"11","position":1,"name":"Dairy & Eggs"}],"variations":[],"add_ons":[],"attributes":[],"choice_options":[],"price":390,"tax":0,"tax_type":"percent","discount":45,"discount_type":"percent","available_time_starts":"00:00:00","available_time_ends":"23:59:00","veg":0,"status":1,"stor …[truncated]
```

### GET `api/v1/vendor/item/status`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/item/status?id=1&status=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/item/stock-limit-list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/item/stock-limit-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### PUT `api/v1/vendor/item/stock-update`

- **Auth:** `vendor`
- **Parameters:** `product_id` (**required**), `current_stock` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/item/stock-update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"product_id":1,"current_stock":"test"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/item/store`

- **Auth:** `vendor`
- **Parameters:** `category_id` (**required**), `store_category_id` (optional), `price` (**required**), `discount` (optional), `video_upload_type` (optional), `video` (optional), `video_link` (optional), `remove_video` (optional), `image` (optional), `translations` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/item/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"category_id":2,"store_category_id":39,"price":100,"discount":1,"video_link":"test","remove_video":"0","translations":"test"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Please enter a valid video link.","content":null,"errors":{"video_link":["Please enter a valid video link."],"image":["The image field is required."],"translations":["Name and description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `video_upload_type`, `video`, `image` — send as `multipart/form-data`.*

### PUT `api/v1/vendor/item/update`

- **Auth:** `vendor`
- **Parameters:** `category_id` (**required**), `store_category_id` (optional), `price` (**required**), `discount` (optional), `video_upload_type` (optional), `video` (optional), `video_link` (optional), `remove_video` (optional), `id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/item/update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"category_id":2,"store_category_id":39,"price":100,"discount":1,"video_link":"test","remove_video":"0","id":1}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Please enter a valid video link.","content":null,"errors":{"video_link":["Please enter a valid video link."],"translations":["Name and description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `video_upload_type`, `video` — send as `multipart/form-data`.*

### POST `api/v1/vendor/make-collected-cash-payment`

- **Auth:** `vendor`
- **Parameters:** `payment_gateway` (**required**), `amount` (**required**), `callback` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/make-collected-cash-payment' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"payment_gateway":"test","amount":100,"callback":"test"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"redirect_link":""},"errors":[]}
```

### POST `api/v1/vendor/make-wallet-adjustment`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/make-wallet-adjustment' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Already Adjusted","content":null,"errors":[]}
```

### GET `api/v1/vendor/message/details`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/message/details' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"status":false,"conversation":null,"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/vendor/message/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/message/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":69,"sender_type":"customer","receiver_type":"vendor","unread_message_count":2,"last_message_time":"2026-07-07 18:19:04","sender":{"id":16,"f_name":"Audit","l_name":"Probe","phone":"+8801700000000","image_full_url":"{{host}}\/storage\/app\/public\/profile\/2026-07-02-6a45fd3b80ee9.webp"},"receiver":{"id":2,"f_name":"Eorange","l_name":"","phone":"02000000002","image_full_url":"{{host}}\/storage\/app\/public\/store\/2024-10-27-671e34990da6e.png"},"last_message":{"sender_id":16,"message":"Jj","file_full_url":["{{host}}\/storage\/app\/public\/conversation\/2026-07-07-6a4c9a5832073.webp"],"is_seen":0,"created …[truncated]
```

### GET `api/v1/vendor/message/search-list`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/message/search-list?name=Ferrero' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### POST `api/v1/vendor/message/send`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/message/send' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Validation failed","content":null,"errors":[{"code":"receiver_id","message":"Invalid receiver"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/notifications`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/notifications' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":24570,"data":{"title":"Order Notification","description":"New order alert, confirm to proceed","order_id":103014,"image":"","type":"new_order"},"status":1,"user_id":null,"vendor_id":3,"delivery_man_id":null,"serviceman_id":null,"order_type":null,"created_at":"2026-08-20 13:20:04","updated_at":"2026-08-20T07:20:04.000000Z"},{"id":24601,"data":{"title":"Order Notification","description":"New order alert, confirm to proceed","order_id":103015,"image":"","type":"new_order"},"status":1,"user_id":null,"vendor_id":3,"delivery_man_id":null,"serviceman_id":null,"order_type":null,"created_at":"2026-08-20 13:22:16 …[truncated]
```

### GET `api/v1/vendor/order`

- **Auth:** `vendor`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/order?order_id=100018' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":100018,"user_id":7,"order_amount":2487.04,"coupon_discount_amount":0,"coupon_discount_title":"","payment_status":"unpaid","order_status":"confirmed","total_tax_amount":27,"payment_method":"cash_on_delivery","transaction_reference":null,"delivery_address_id":null,"delivery_man_id":null,"coupon_code":null,"order_note":null,"order_type":"delivery","checked":1,"store_id":3,"created_at":"2022-03-23 21:50:37","updated_at":"2026-08-27T07:59:35.000000Z","delivery_charge":2190.04,"delivery_type":null,"delivery_type_charge":0,"schedule_at":"2022-03-23 21:50:37","callback":null,"otp":"1845","pending":"2022-03-23 21:50:37", …[truncated]
```

### GET `api/v1/vendor/order-details`

- **Auth:** `vendor`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/order-details?order_id=100018' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[{"id":14,"item_id":127,"order_id":100018,"price":300,"item_details":{"id":127,"name":"Orbit Fresh Mint","description":"1. ORBIT Chewing Gum is approved by the American Dental Association\r\n2. Keep your favorite gum on hand with this bulk packaged\r\n3. Freshen breath and boost your confidence with ORBIT Gum.\r\n4. Contains twelve (12) 14-piece packs of ORBIT Gum Sweet Mint Sugarfree Chewing Gum","image":"2022-03-22-6239d677852e5.png","category_id":11,"category_ids":[{"id":"11","position":1}],"variations":[],"add_ons":[],"attributes":[],"choice_options":[],"price":300,"tax":10,"tax_type":"percent","discount":10,"disc …[truncated]
```

### GET `api/v1/vendor/order-edit-log`

- **Auth:** `vendor`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/order-edit-log?order_id=100018' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/vendor/package-view`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/package-view' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":6,"package_name":"tets","price":344,"validity":345,"max_order":"unlimited","max_product":"unlimited","pos":1,"mobile_app":0,"chat":0,"review":0,"self_delivery":0,"status":1,"default":0,"colour":null,"text":"dsfgs","created_at":"2026-03-12T15:35:13.000000Z","updated_at":"2026-03-12T15:35:13.000000Z","module_type":"all","translations":[{"id":5381,"translationable_type":"App\\Models\\SubscriptionPackage","translationable_id":6,"locale":"en","key":"package_name","value":"tets","created_at":null,"updated_at":null},{"id":5382,"translationable_type":"App\\Models\\SubscriptionPackage","translationable_id":6,"lo …[truncated]
```

### GET `api/v1/vendor/profile`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/profile' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":3,"f_name":"Audit","l_name":"Probe","phone":"02000000002","email":"grocery.store2@demo.com","email_verified_at":null,"created_at":"2022-03-22T11:19:28.000000Z","updated_at":"2026-08-27T08:13:28.000000Z","rejection_note":"International Bank","image":null,"status":1,"firebase_token":null,"login_remember_token":"<REDACTED>","order_count":260,"todays_order_count":0,"this_week_order_count":0,"this_month_order_count":0,"todays_earning":0,"this_week_earning":0,"this_month_earning":0,"member_since_days":1618,"cash_in_hands":0,"balance":0,"total_earning":22667.71,"Payable_Balance":0,"withdraw_able_balance":0,"adjust_able …[truncated]
```

### DELETE `api/v1/vendor/reel/delete`

- **Auth:** `vendor`
- **Parameters:** `reel_id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/reel/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"reel_id":2}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not Found","content":null,"errors":[{"code":"not_found","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/reel/details`

- **Auth:** `vendor`
- **Parameters:** `reel_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/reel/details?reel_id=2' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not Found","content":null,"errors":[{"code":"not_found","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/reel/list`

- **Auth:** `vendor`
- **Parameters:** `limit` (optional), `offset` (optional), `status` (optional), `sort_by` (optional), `search` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/reel/list?limit=10&offset=1&status=1&sort_by=latest&search=test' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Invalid status filter","content":null,"errors":{"status":["Invalid status filter"]}}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/vendor/reel/status`

- **Auth:** `vendor`
- **Parameters:** `reel_id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/reel/status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"reel_id":2,"status":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not Found","content":null,"errors":[{"code":"not_found","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/reel/store`

- **Auth:** `vendor`
- **Parameters:** `description` (**required**), `translations` (optional), `thumbnail` (optional), `video` (optional), `is_always_visible` (optional), `dates` (conditional — `required_without:is_always_visible`), `status` (optional), `product_id` (optional), `order_now_button` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/reel/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"description":"Audit probe description","translations":"test","is_always_visible":"1","dates":"2026-08-27","status":1,"product_id":1,"order_now_button":1}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"JSON","content":null,"errors":{"translations":["JSON","Description in english is required"],"thumbnail":["Image is required"],"video":["Video is required"]}}
```
- *Takes file upload(s) not exercised here: `thumbnail`, `video` — send as `multipart/form-data`.*

### PUT `api/v1/vendor/reel/update`

- **Auth:** `vendor`
- **Parameters:** `description` (**required**), `translations` (optional), `thumbnail` (optional), `video` (optional), `is_always_visible` (optional), `dates` (conditional — `required_without:is_always_visible`), `status` (optional), `product_id` (optional), `order_now_button` (optional), `reel_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/reel/update' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"description":"Audit probe description","translations":"test","is_always_visible":"1","dates":"2026-08-27","status":1,"product_id":1,"order_now_button":1,"reel_id":2}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"JSON","content":null,"errors":{"translations":["JSON","Description in english is required"]}}
```
- *Takes file upload(s) not exercised here: `thumbnail`, `video` — send as `multipart/form-data`.*

### DELETE `api/v1/vendor/remove-account`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/remove-account' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Please complete your ongoing and accepted orders","content":null,"errors":[]}
```

### POST `api/v1/vendor/request-withdraw`

- **Auth:** `vendor`
- **Parameters:** `amount` (**required**), `id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/request-withdraw' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"amount":100,"id":1}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Insufficient balance","content":null,"errors":[{"code":"amount","message":"Insufficient balance"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/schedule/store`

- **Auth:** `vendor`
- **Parameters:** `opening_time` (**required**), `closing_time` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/schedule/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"opening_time":"2026-08-27","closing_time":"2026-08-27"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The opening time does not match the format H:i:s.","content":null,"errors":{"opening_time":["The opening time does not match the format H:i:s."],"closing_time":["The closing time does not match the format H:i:s.","End time must be after the start time"]}}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/vendor/schedule/{store_schedule}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/schedule/717' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_delete_200","message":"Successfully deleted","content":null,"errors":[]}
```

### PUT `api/v1/vendor/send-order-otp`

- **Auth:** `vendor`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/send-order-otp' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"order_id":100018}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":null,"errors":[]}
```

### POST `api/v1/vendor/service/ai/analyze-image`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/ai/analyze-image' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"message":"Image is required"}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/ai/description`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/ai/description' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The name field is required.","errors":{"name":["The name field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/ai/general-setup`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/ai/general-setup' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The name field is required.","errors":{"name":["The name field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/service/ai/generate-title-suggestions`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/ai/generate-title-suggestions' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"name":"Deep"}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The keywords field is required.","errors":{"keywords":["The keywords field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/ai/long-description`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/ai/long-description' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The name field is required.","errors":{"name":["The name field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/ai/price-variation`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/ai/price-variation' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The name field is required.","errors":{"name":["The name field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/ai/seo`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/ai/seo' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The name field is required.","errors":{"name":["The name field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/ai/tags`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/ai/tags' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The name field is required.","errors":{"name":["The name field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/ai/title`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/ai/title' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The name field is required.","errors":{"name":["The name field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/service/basic-campaigns/join`

- **Auth:** `vendor`
- **Parameters:** `campaign_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/basic-campaigns/join' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"campaign_id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"campaign","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/service/basic-campaigns/leave`

- **Auth:** `vendor`
- **Parameters:** `campaign_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/basic-campaigns/leave' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"campaign_id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"campaign","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/basic-campaigns/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/basic-campaigns/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[],"errors":[]}
```

### DELETE `api/v1/vendor/service/bids/{offer}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/service/bids/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"bid","message":"Bid not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/bulk-export`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/bulk-export' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
PK   ?q]?v_       [Content_Types].xml??Mn?0???"?J ]TUE`Q?e?Tz מ ??cܾ?$?R?%?y???8cO?{k?"j?J6)?,'??n]???k??2L?)a??? ?|6??0??KV??8GY?X? ???G+M?!7b ?~<~?һ.???f????*?5){??6?DFK????,{ٓ?{m?????.l?GKE??`??]RHū0??????Ғ??fŎ???9+?~G? ??`? ? ɚ? +???[??ބ??|o???͗??????[B????w??v>???W?q?z|v>???Az?+ݤD??"uް??댜N???I?I?MV??"o??vhO??':?>?﮵?7PK   ?q]"? ?   9     xl/workbook.xml???N?0 ??<E?;K????.i??x??FK?*??=?8?m??????+'w??Q????G<J?|???????V?I?z?&????}J9E???Y{?k]Z?u?)?nd!??$%c????.?0?LTs?OM??3F??Ж?0d??H?2^2q]!?VS?s\g??~?a͎1??íޚ?[?3 ??ъ?Ê?v?Q?1???<?=? PK   ?q]???p         xl/styles.xml?RMk?0 ??W?W???1 …[truncated]
```

### POST `api/v1/vendor/service/bulk-import`

- **Auth:** `vendor`
- **Parameters:** `services_file` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/bulk-import' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"services_file":"test"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"file","message":"You have uploaded a wrong format file"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/campaigns/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/campaigns/details/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"campaign","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/campaigns/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/campaigns/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":1,"limit":0,"offset":0,"campaigns":[{"id":4,"name":"Monsoon Offer","slug":"monsoon-offer-sd","short_description":"Monsoon Offer short","long_description":"Monsoon Offer long","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":700,"min_bid_price":null,"discount":15,"discount_type":"percent","discounted_price":595,"variations":[],"tags":[],"module_id":16,"store_id":229,"category_id":2,"sub_category_id":null,"store_category_id":null,"category":{"id":2,"name":"Personal Care","slug":"seafood2"},"sub_category":null,"store_category":null,"provider_name":"Seed Service Provider","provider_imag …[truncated]
```

### GET `api/v1/vendor/service/categories/category-wise-services/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/categories/category-wise-services/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":0,"limit":25,"offset":1,"services":[]},"errors":[]}
```

### GET `api/v1/vendor/service/custom-requests`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/custom-requests' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":0,"limit":20,"offset":1,"data":[]},"errors":[]}
```

### GET `api/v1/vendor/service/custom-requests/{customServiceRequest}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/custom-requests/13' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"request","message":"Request not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/service/custom-requests/{customServiceRequest}/bids`

- **Auth:** `vendor`
- **Parameters:** `offer_price` (**required**), `note` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/custom-requests/13/bids' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"offer_price":"test","note":"audit probe"}'
```
- **Status:** 422
- **Response:**
```json
{"message":"The Offer Price must be a number.","errors":{"offer_price":["The Offer Price must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/custom-requests/{customServiceRequest}/other-bids`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/custom-requests/13/other-bids' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"bids","message":"Viewing other providers offers is disabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### DELETE `api/v1/vendor/service/delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/service/delete/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"service","message":"Service not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/details/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"service","message":"Service not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### DELETE `api/v1/vendor/service/faq/delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/service/faq/delete/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"faq","message":"Faq not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/faq/list/{service_id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/faq/list/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"service","message":"Service not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/faq/status/{id}/{status}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/faq/status/1/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"faq","message":"Faq not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/service/faq/store/{service_id}`

- **Auth:** `vendor`
- **Parameters:** `question` (**required**), `answer` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/faq/store/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"question":"test","answer":"test"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"service","message":"Service not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/service/faq/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `question` (**required**), `answer` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/faq/update/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"question":"test","answer":"test"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"faq","message":"Faq not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/gallery`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/gallery' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"service_gallery","message":"Service gallery is disabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/gallery/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/gallery/details/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":1,"name":"Deep Cleaning","slug":"deep-cleaning-sd","short_description":"Deep Cleaning short","long_description":"Deep Cleaning long description","thumbnail_full_url":null,"additional_images_full_url":[],"base_price":1200,"discount":0,"discount_type":"percent","is_favorite":false,"tax_ids":[],"tax_data":[],"variations":[],"tags":[],"recommended":1,"is_approved":1,"status":1,"order_count":24,"avg_rating":4.5,"rating_count":2,"module_id":16,"module_type":null,"store_id":2,"store_name":"Click & Collect","provider_name":"Click & Collect","provider_image_full_url":"{{host}}\/storage\/app\/public\/store\/2022-03-22-623 …[truncated]
```

### GET `api/v1/vendor/service/get-booking-report`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/get-booking-report' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":3,"limit":25,"offset":1,"summary":{"total":3,"completed":1,"ongoing":0,"in_progress":1,"on_hold":0,"canceled":0,"total_amount":4500},"bookings":[{"id":102691,"display_id":"102691","booking_type":"regular","multi_booking_type":null,"parent_booking_id":null,"is_repeat_parent":false,"child_bookings_count":0,"active_booking_id":102691,"active_display_id":"102691","active_booking_status":"pending","active_status_label":"Pending","active_schedule_at":"2026-08-26 15:25:13","is_custom":false,"is_campaign":false,"booking_status":"pending","status_label":"Pending","payment_status":"unpaid","payment_method":"cash_o …[truncated]
```

### GET `api/v1/vendor/service/get-disbursement-report`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/get-disbursement-report' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":0,"limit":25,"offset":1,"pending":0,"completed":0,"canceled":0,"complete_day":2,"disbursements":[]},"errors":[]}
```

### GET `api/v1/vendor/service/get-earning-report`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/get-earning-report' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"summary":{"total_earning":0,"previous_total_earning":0,"total_earning_percentage":0,"total_earning_positive":false,"total_expense":0,"previous_total_expense":0,"total_expense_percentage":0,"total_expense_positive":false,"net_income":0,"previous_net_income":0,"net_income_percentage":0,"net_income_positive":false,"counts":{"earning":0,"expense":0,"subscription":0},"breakdown":{"booking_store_earning":0,"booking_store_earning_percentage":0,"tax_amount":0,"tax_amount_percentage":0},"booking_commission":0,"booking_commission_percentage":0,"vendor_expense_amount":0,"vendor_expense_amount_percentage":0,"discount_on_booking …[truncated]
```

### GET `api/v1/vendor/service/get-expense`

- **Auth:** `vendor`
- **Parameters:** `from` (**required**), `to` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/get-expense?from=2025-08-27&to=2026-08-28' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":0,"limit":25,"offset":1,"expense":[]},"errors":[]}
```

### GET `api/v1/vendor/service/get-tax-report`

- **Auth:** `vendor`
- **Parameters:** `from` (**required**), `to` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/get-tax-report?from=2025-08-27&to=2026-08-28' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":1,"limit":25,"offset":1,"taxSummary":[],"totalOrders":1,"totalOrderAmount":1500,"totalTax":0,"orders":[{"id":102693,"booking_amount":1500,"tax_amount":0,"booking_type":"regular","created_at":"2026-08-25T09:25:13.000000Z","booking_status":"completed","payment_status":"paid","attachments_full_url":[],"completion_evidence_full_url":[]}]},"errors":[]}
```

### GET `api/v1/vendor/service/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":0,"limit":0,"offset":0,"services":[]},"errors":[]}
```

### DELETE `api/v1/vendor/service/pending-delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/service/pending-delete/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"service","message":"Service not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/pending-details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/pending-details/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"service","message":"Service not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/pending-list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/pending-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":0,"limit":0,"offset":0,"services":[]},"errors":[]}
```

### GET `api/v1/vendor/service/reviews`

- **Auth:** `vendor`
- **Parameters:** `service_id` (optional)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/reviews?service_id=1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":1,"limit":0,"offset":0,"provider_can_reply_review":false,"rating_summary":{"avg_rating":5,"total_reviews":1,"breakdown":[{"label":"excellent","star":5,"count":1},{"label":"good","star":4,"count":0},{"label":"average","star":3,"count":0},{"label":"below","star":2,"count":0},{"label":"poor","star":1,"count":0}]},"reviews":[{"id":6,"review_id":"SD-0","service_id":1,"booking_id":null,"rating":5,"comment":"Excellent work","attachment":[],"reply":null,"replied_at":null,"service_name":"Deep Cleaning","customer":{"id":8,"f_name":"Audit","l_name":"Probe","image_full_url":"{{host}}\/storage\/app\/public\/profile\/ …[truncated]
```

### PUT `api/v1/vendor/service/reviews/reply`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `reply` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/service/reviews/reply' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1,"reply":"test"}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"reply","message":"Review reply is disabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/reviews/status/{id}/{status}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/reviews/status/1/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Review not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/service/status/{id}/{status}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/status/1/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"service","message":"Service not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/service/store`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**), `name.0` (**required**), `name.*` (optional), `short_description.0` (**required**), `short_description.*` (optional), `long_description.*` (optional), `category_id` (**required**), `base_price` (**required**), `discount` (optional), `discount_type` (optional), `image` (optional), `item_images.*` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"name":[],"category_id":2,"base_price":"test","discount":1,"discount_type":"percent"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The name field is required.","content":null,"errors":{"name":["The name field is required."],"name.0":["Default name is required"],"short_description.0":["Default description is required"],"base_price":["The base price must be a number."],"image":["Image is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### POST `api/v1/vendor/service/store-category/assign-items`

- **Auth:** `vendor`
- **Parameters:** `category_id` (**required**), `food_ids` (optional), `item_ids` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/store-category/assign-items' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"category_id":2,"food_ids":[1],"item_ids":[101]}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"disabled","message":"Store category feature is disabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/store-category/assignable-items/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/store-category/assignable-items/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 403
- **Response:**
```json
{"identical_code":"forbidden_403","message":"Permission denied","content":null,"errors":[{"code":"disabled","message":"Store category feature is disabled"}]}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/service/store-category/items/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/store-category/items/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":[],"errors":[]}
```

### GET `api/v1/vendor/service/store-setup`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/service/store-setup' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"booking_types":{"instant_booking":false,"repeat_booking":false,"schedule_booking":false,"instant_booking_editable":false,"repeat_booking_editable":false,"schedule_booking_editable":true},"service_location":{"choose_service_location":["customer"],"provider_place_editable":false},"serviceman_permission":{"serviceman_can_cancel_booking":false,"serviceman_can_cancel_booking_editable":false}},"errors":[]}
```

### PUT `api/v1/vendor/service/store-setup`

- **Auth:** `vendor`
- **Parameters:** `instant_booking` (optional), `repeat_booking` (optional), `schedule_booking` (optional), `choose_service_location` (optional), `choose_service_location.*` (optional), `serviceman_can_cancel_booking` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/service/store-setup' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"instant_booking":1,"repeat_booking":1,"schedule_booking":1,"choose_service_location":[],"serviceman_can_cancel_booking":1}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The choose service location must have at least 1 items.","content":null,"errors":{"choose_service_location":["The choose service location must have at least 1 items."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### POST `api/v1/vendor/service/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `name` (**required**), `name.0` (**required**), `name.*` (optional), `short_description.0` (**required**), `short_description.*` (optional), `long_description.*` (optional), `category_id` (**required**), `base_price` (**required**), `discount` (optional), `discount_type` (optional), `image` (optional), `item_images.*` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/service/update/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"name":[],"category_id":2,"base_price":"test","discount":1,"discount_type":"percent"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The name field is required.","content":null,"errors":{"name":["The name field is required."],"name.0":["Default name is required"],"short_description.0":["Default description is required"],"base_price":["The base price must be a number."]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### DELETE `api/v1/vendor/serviceman/delete/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/serviceman/delete/23' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"message":"Serviceman removed"},"errors":[]}
```

### GET `api/v1/vendor/serviceman/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/serviceman/details/23' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"serviceman":{"id":23,"f_name":"Seed","l_name":"Serviceman Two","full_name":"Seed Serviceman Two","email":"svcseed.sm1@mart.test","phone":"+8801700000904","image_full_url":null,"identity_type":"passport","identity_number":"test","identity_image_full_url":[],"zone_id":1,"type":"full_time","status":true,"active":true,"application_status":"approved","member_since_days":0,"booking_count":0,"assigned_booking_count":0,"current_bookings":0,"total_assigned":0,"ongoing_bookings":0,"completed_bookings":0,"canceled_bookings":0,"provider":{"id":229,"name":"Seed Service Provider","phone":"+8801700000902","zone_id":1,"logo_full_ur …[truncated]
```

### GET `api/v1/vendor/serviceman/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/serviceman/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":2,"limit":10,"offset":1,"total":2,"active":2,"inactive":0,"servicemen":[{"id":23,"f_name":"Seed","l_name":"Serviceman Two","full_name":"Seed Serviceman Two","email":"svcseed.sm1@mart.test","phone":"+8801700000904","image_full_url":null,"status":true,"active":true,"application_status":"approved","booking_count":0},{"id":9,"f_name":"Audit","l_name":"Probe","full_name":"Audit Probe","email":"svcseed.sm0@mart.test","phone":"+8801700000903","image_full_url":null,"status":true,"active":true,"application_status":"approved","booking_count":0}]},"errors":[]}
```

### GET `api/v1/vendor/serviceman/services/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/serviceman/services/23' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"total_size":0,"limit":10,"offset":1,"services":[]},"errors":[]}
```

### GET `api/v1/vendor/serviceman/status/{id}/{status}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/serviceman/status/23/1' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"message":"Serviceman status updated","status":true},"errors":[]}
```

### POST `api/v1/vendor/serviceman/store`

- **Auth:** `vendor`
- **Parameters:** `f_name` (**required**), `l_name` (optional), `identity_number` (**required**), `identity_type` (optional), `email` (**required**), `phone` (**required**), `image` (optional), `identity_image` (optional), `identity_image.*` (optional), `password` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/serviceman/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"f_name":"Audit","l_name":"Probe","identity_number":"test","identity_type":"passport","email":"audit64ae4a60@example.com","phone":"+880936940814","identity_image":[],"password":"Str0ng@Pass1"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Image is required","content":null,"errors":{"image":["Image is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### POST `api/v1/vendor/serviceman/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `f_name` (**required**), `l_name` (optional), `identity_number` (**required**), `identity_type` (optional), `email` (**required**), `phone` (**required**), `image` (optional), `identity_image` (optional), `identity_image.*` (optional), `password` (optional), `delete_identity_image` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/serviceman/update/23' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 16' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"f_name":"Audit","l_name":"Probe","identity_number":"test","identity_type":"passport","email":"svcseed.vendor@mart.test","phone":"+8801700000900","identity_image":[],"password":"Str0ng@Pass1","delete_identity_image":[]}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"message":"Serviceman updated successfully","serviceman":{"id":23,"f_name":"Audit","l_name":"Probe","full_name":"Audit Probe","email":"svcseed.vendor@mart.test","phone":"+8801700000900","image_full_url":null,"identity_type":"passport","identity_number":"test","identity_image_full_url":[],"zone_id":1,"type":"full_time","status":true,"active":true,"application_status":"approved","member_since_days":0,"booking_count":0,"assigned_booking_count":0,"current_bookings":0,"total_assigned":0,"ongoing_bookings":0,"completed_bookings":0,"canceled_bookings":0,"provider":{"id":229,"name":"Seed Service Provider","phone":"+880170000 …[truncated]
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### POST `api/v1/vendor/store-category/assign-items`

- **Auth:** `vendor`
- **Parameters:** `category_id` (**required**), `item_ids` (optional)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/store-category/assign-items' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"category_id":2,"item_ids":[101]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The item ids must be a string.","content":null,"errors":{"item_ids":["The item ids must be a string."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/vendor/store-category/assignable-items/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/store-category/assignable-items/39' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"category":{"id":39,"name":"eorange category"},"unassigned_count":9,"data":[{"id":402,"name":"Fresh Flavor Dhaka Essentials","image_full_url":null,"price":10,"store_category_id":39,"is_assigned":true,"variations_count":3},{"id":127,"name":"Orbit Fresh Mint","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d677852e5.png","price":300,"store_category_id":null,"is_assigned":false,"variations_count":0},{"id":121,"name":"Pillsbury Best Whole Wheat Flour","image_full_url":"{{host}}\/storage\/app\/public\/product\/2022-03-22-6239d4996f3e7.png","price":300,"store_category_id":null,"is_assigned":false, …[truncated]
```

### DELETE `api/v1/vendor/store-category/delete`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/store-category/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"store-category-404","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/store-category/details/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/store-category/details/39' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"id":39,"store_id":3,"module_id":1,"name":"eorange category","slug":"eorange-category","image":"2026-07-05-6a4a3f549d68d.webp","image_full_url":"{{host}}\/storage\/app\/public\/category\/2026-07-05-6a4a3f549d68d.webp","priority":0,"status":0,"created_at":"2026-07-05T17:26:12.000000Z","translations":[{"locale":"en","key":"name","value":"eorange category"}]},"errors":[]}
```

### GET `api/v1/vendor/store-category/items/{id}`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/store-category/items/39' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":402,"name":"Fresh Flavor Dhaka Essentials","slug":"fresh-flavor-dhaka-essentials","image_full_url":null,"images_full_url":[],"price":10,"discount":10,"discount_type":"percent","store_discount":0,"flash_sale":0,"stock":0,"unit_type":"Kg","maximum_cart_quantity":10,"veg":0,"organic":0,"is_halal":1,"avg_rating":0,"rating_count":0,"available_time_starts":"00:00:00","available_time_ends":"23:59:59","brand_name":null,"category_ids":[{"id":"3","position":1},{"id":"50","position":2}],"module_id":1,"module_type":"grocery","store_id":3,"store_name":"Eorange","store_slug":"eorange3","store_image_full_url":"{{host} …[truncated]
```

### GET `api/v1/vendor/store-category/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/store-category/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":40,"store_id":3,"module_id":1,"name":"Chicken Biryani with Egg","slug":"chicken-biryani-with-egg","image":"2026-07-11-6a51ee218cdbe.webp","image_full_url":"{{host}}\/storage\/app\/public\/category\/2026-07-11-6a51ee218cdbe.webp","priority":0,"status":1,"items_count":0,"created_at":"2026-07-11T13:17:53.000000Z"},{"id":39,"store_id":3,"module_id":1,"name":"eorange category","slug":"eorange-category","image":"2026-07-05-6a4a3f549d68d.webp","image_full_url":"{{host}}\/storage\/app\/public\/category\/2026-07-05-6a4a3f549d68d.webp","priority":0,"status":0,"items_count":1,"created_at":"2026-07-05T17:26:12.0000 …[truncated]
```

### POST `api/v1/vendor/store-category/priority`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `priority` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/store-category/priority' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1,"priority":"0"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"store-category-404","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/store-category/status`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `status` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/store-category/status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1,"status":"0"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"store-category-404","message":"Not Found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/store-category/store`

- **Auth:** `vendor`
- **Parameters:** `image` (optional), `priority` (optional), `name` (**required**), `name.0` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/store-category/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"priority":"0","name":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Image is required","content":null,"errors":{"image":["Image is required"],"name":["The name field is required."],"name.0":["Default name is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### POST `api/v1/vendor/store-category/update/{id}`

- **Auth:** `vendor`
- **Parameters:** `image` (optional), `priority` (optional), `name` (**required**), `name.0` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/store-category/update/39' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"priority":"0","name":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The name field is required.","content":null,"errors":{"name":["The name field is required."],"name.0":["Default name is required"]}}
```
- *Takes file upload(s) not exercised here: `image` — send as `multipart/form-data`.*

### GET `api/v1/vendor/subscription-transaction`

- **Auth:** `vendor`
- **Parameters:** `from` (**required**), `to` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/subscription-transaction?from=2026-08-27&to=2026-08-27' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### GET `api/v1/vendor/unit`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/unit' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"unit":"Kg","created_at":"2022-03-16T14:32:07.000000Z","updated_at":"2022-03-16T14:32:07.000000Z","translations":[]},{"id":2,"unit":"Pcs","created_at":"2022-03-16T14:32:52.000000Z","updated_at":"2022-03-16T14:32:59.000000Z","translations":[]},{"id":3,"unit":"Ltr","created_at":"2022-03-22T13:49:40.000000Z","updated_at":"2022-03-22T13:49:40.000000Z","translations":[]},{"id":4,"unit":"Pack","created_at":"2022-03-22T19:27:18.000000Z","updated_at":"2022-03-22T19:27:18.000000Z","translations":[]},{"id":5,"unit":"5","created_at":"2024-10-31T14:42:34.000000Z","updated_at":"2024-10-31T14:42:34.000000Z","transl …[truncated]
```

### POST `api/v1/vendor/update-active-status`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/update-active-status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Store opened","content":null,"errors":[]}
```

### PUT `api/v1/vendor/update-announcment`

- **Auth:** `vendor`
- **Parameters:** `announcement_status` (**required**), `announcement_message` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/update-announcment' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"announcement_status":"test","announcement_message":"test"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Profile updated successfully","content":null,"errors":[]}
```

### PUT `api/v1/vendor/update-basic-info`

- **Auth:** `vendor`
- **Parameters:** `contact_number` (**required**), `logo` (optional), `cover_photo` (optional), `meta_image` (optional), `meta_title` (optional), `translations` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/update-basic-info' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"contact_number":"02000000002","meta_title":"test","translations":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"Name and address in english is required","content":null,"errors":{"translations":["Name and address in english is required"]}}
```
- *Takes file upload(s) not exercised here: `logo`, `cover_photo`, `meta_image` — send as `multipart/form-data`.*

### PUT `api/v1/vendor/update-business-setup`

- **Auth:** `vendor`
- **Parameters:** `delivery` (**required**), `prescription_order` (**required**), `take_away` (**required**), `schedule_order` (**required**), `veg` (**required**), `non_veg` (**required**), `minimum_order` (**required**), `gst` (conditional — `required_if:gst_status,1`), `minimum_delivery_time` (**required**), `maximum_delivery_time` (**required**), `delivery_time_type` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/update-business-setup' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"delivery":1,"prescription_order":1,"take_away":1,"schedule_order":1,"veg":1,"non_veg":1,"minimum_order":"test","gst":"test","minimum_delivery_time":"09:00","maximum_delivery_time":"09:00","delivery_time_type":"min"}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The minimum order must be a number.","content":null,"errors":{"minimum_order":["The minimum order must be a number."],"minimum_delivery_time":["The minimum delivery time must be a number."],"maximum_delivery_time":["The maximum delivery time must be a number."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/vendor/update-fcm-token`

- **Auth:** `vendor`
- **Parameters:** `fcm_token` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/update-fcm-token' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"fcm_token":"test"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"successfully updated!","content":null,"errors":[]}
```

### PUT `api/v1/vendor/update-order`

- **Auth:** `vendor`
- **Parameters:** `order_id` (**required**), `carts` (**required**), `carts.*.item_id` (**required**), `carts.*.quantity` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/update-order' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"order_id":100018,"carts":[]}'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The carts field is required.","content":null,"errors":{"carts":["The carts field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### PUT `api/v1/vendor/update-order-amount`

- **Auth:** `vendor`
- **Parameters:** `order_id` (**required**)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/update-order-amount' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"order_id":100018}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Order updated successfully","content":null,"errors":[]}
```

### PUT `api/v1/vendor/update-order-status`

- **Auth:** `vendor`
- **Parameters:** `order_id` (**required**), `reason` (conditional — `required_if:status,canceled`), `status` (**required**), `order_proof` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/update-order-status' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"order_id":100018,"reason":"audit probe","status":"confirmed","order_proof":[]}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Status updated","content":null,"errors":[]}
```

### PUT `api/v1/vendor/update-profile`

- **Auth:** `vendor`
- **Parameters:** `f_name` (**required**), `l_name` (**required**), `phone` (**required**), `password` (optional)
- **Request:**
```bash
curl -X PUT '{{host}}/api/v1/vendor/update-profile' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"f_name":"Audit","l_name":"Probe","phone":"02000000002","password":"Str0ng@Pass1"}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_update_200","message":"Profile updated successfully","content":null,"errors":[]}
```

### GET `api/v1/vendor/wallet-payment-list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/wallet-payment-list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":0,"from":null,"to":null}},"errors":[]}
```

### DELETE `api/v1/vendor/withdraw-method/delete`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**)
- **Request:**
```bash
curl -X DELETE '{{host}}/api/v1/vendor/withdraw-method/delete' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### GET `api/v1/vendor/withdraw-method/list`

- **Auth:** `vendor`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/vendor/withdraw-method/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":102,"store_id":3,"delivery_man_id":null,"withdrawal_method_id":1,"method_name":"Card","method_fields":[],"is_default":false,"created_at":"2026-08-27T07:59:37.000000Z","updated_at":"2026-08-27T07:59:37.000000Z"},{"id":100,"store_id":3,"delivery_man_id":null,"withdrawal_method_id":1,"method_name":"Card","method_fields":[],"is_default":false,"created_at":"2026-08-27T07:58:10.000000Z","updated_at":"2026-08-27T07:58:10.000000Z"},{"id":98,"store_id":3,"delivery_man_id":null,"withdrawal_method_id":1,"method_name":"Card","method_fields":[],"is_default":false,"created_at":"2026-08-27T07:56:26.000000Z","updated_a …[truncated]
```

### POST `api/v1/vendor/withdraw-method/make-default`

- **Auth:** `vendor`
- **Parameters:** `id` (**required**), `is_default` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/withdraw-method/make-default' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"id":1,"is_default":"test"}'
```
- **Status:** 404
- **Response:**
```json
{"identical_code":"default_404","message":"Not found","content":null,"errors":[{"code":"id","message":"Not found"}]}
```
- *404 here because the probe used a placeholder id; supply a real one owned by the account.*

### POST `api/v1/vendor/withdraw-method/store`

- **Auth:** `vendor`
- **Parameters:** `withdraw_method_id` (**required**)
- **Request:**
```bash
curl -X POST '{{host}}/api/v1/vendor/withdraw-method/store' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1' \
  -H 'vendorType: owner' \
  -H 'Authorization: Bearer {{provider_token}}' \
  -d '{"withdraw_method_id":1}'
```
- **Status:** 201
- **Response:**
```json
{"identical_code":"default_store_201","message":"Successfully added!","content":null,"errors":[]}
```

### GET `api/v1/zone/check`

- **Auth:** `public`
- **Parameters:** `lat` (**required**), `lng` (**required**), `zone_id` (**required**)
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/zone/check?lat=23.735129&lng=90.425614' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 422
- **Response:**
```json
{"identical_code":"unprocessable_entity_422","message":"The zone id field is required.","content":null,"errors":{"zone_id":["The zone id field is required."]}}
```
- *The error body above lists the fields this endpoint still wants.*

### GET `api/v1/zone/list`

- **Auth:** `public`
- **Request:**
```bash
curl -X GET '{{host}}/api/v1/zone/list' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-localization: en' \
  -H 'zoneId: [1]' \
  -H 'latitude: 23.735129' \
  -H 'longitude: 90.425614' \
  -H 'moduleId: 1'
```
- **Status:** 200
- **Response:**
```json
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[{"id":1,"name":"Main Demo Zone","formated_coordinates":[{"lat":68.264543333074,"lng":-178.18290256214},{"lat":67.620974758356,"lng":-175.50223849964},{"lat":66.786754285776,"lng":-171.72294162464},{"lat":66.13745162053,"lng":-169.87723849964},{"lat":65.562138789911,"lng":-170.97587131214},{"lat":64.410272283991,"lng":-172.90946506214},{"lat":64.973826327668,"lng":-175.41434787464},{"lat":65.670993202543,"lng":-178.09501193714},{"lat":66.490523189999,"lng":-177.96317599964},{"lat":66.279275649039,"lng":179.97139431286},{"lat":65.010981064695,"lng":179.61983181286},{"lat":62.627756209977,"lng":179.09248806286}, …[truncated]
```

