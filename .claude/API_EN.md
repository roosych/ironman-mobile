# Ironman API — Documentation v1

**Base URL:** `https://your-domain.com/api/v1`
**Data format:** JSON
**Authentication:** Laravel Sanctum (Bearer Token)

---

## Table of Contents

1. [General Rules](#1-general-rules)
2. [Authentication](#2-authentication)
3. [User Profile](#3-user-profile)
4. [Photos](#4-photos)
5. [FCM Tokens (Push Notifications)](#5-fcm-tokens)
6. [Notifications](#6-notifications)
7. [Athletes](#7-athletes)
8. [Rankings](#8-rankings)
9. [Races](#9-races)
10. [Upcoming Races](#10-upcoming-races)
11. [Race Results](#11-race-results)
12. [Result Transfer](#12-result-transfer)
13. [Policies & Documents](#13-policies--documents)
14. [Admin Panel](#14-admin-panel)

---

## 1. General Rules

### 1.1 Response Format

All responses follow a unified format:

**Success:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Success with message:**
```json
{
  "success": true,
  "message": "Operation completed successfully.",
  "data": { ... }
}
```

**Error (validation 422, auth 401, etc.):**
```json
{
  "success": false,
  "errors": {
    "field": ["Error message"]
  }
}
```

### 1.2 Authentication

For protected endpoints, pass the token in the header:
```
Authorization: Bearer {token}
```

### 1.3 Localization

All text responses (messages, errors) are automatically translated.

**Language detection priority:**
1. Authenticated user's `locale` field in the database
2. `locale` parameter in the request body
3. `Accept-Language` HTTP header
4. Application default locale (`en`)

**Supported languages:** `en`, `ru`, `az`

### 1.4 Throttle (Rate Limiting)

Public endpoints: **60 requests per minute** per IP.

### 1.5 HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Unprocessable Entity (validation error) |
| 500 | Internal Server Error |

### 1.6 Race Types (`race_type`)

| Value | Description |
|-------|-------------|
| `ironman` | Ironman (full distance) |
| `ironman_70_3` | Ironman 70.3 (half distance) |
| `5150` | Sprint 5150 |

### 1.7 Time Format

All times (swim, bike, run, etc.) are sent as **seconds** (integer) when creating/updating, and returned as `"HH:MM:SS"` strings in responses.

Examples:
- Input: `3600` → Output: `"01:00:00"`
- Input: `0` → Output: `"00:00:00"`

---

## 2. Authentication

### 2.1 Register

```
POST /auth/register
```

**Access:** Public
**Description:** Registers a new user. Automatically creates an athlete profile. Sends an email verification message.

**Request body:**
```json
{
  "name": "Ivan Petrov",
  "email": "ivan@example.com",
  "password": "SecurePass123!",
  "password_confirmation": "SecurePass123!",
  "country_iso": "RU",
  "locale": "en"
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `name` | string | Yes | max:255 |
| `email` | string | Yes | valid email, unique |
| `password` | string | Yes | Laravel default password rules (min 8 characters) |
| `password_confirmation` | string | Yes | must match `password` |
| `country_iso` | string | Yes | 2 uppercase letters (ISO 3166-1 alpha-2), e.g. `RU`, `AZ` |
| `locale` | string | No | `en`, `ru` |

**Response 201:**
```json
{
  "success": true,
  "message": "Registration successful.",
  "data": {
    "user": {
      "id": 1,
      "name": "Ivan Petrov",
      "email": "ivan@example.com",
      "locale": "en",
      "verified": false,
      "profile": {
        "id": 1,
        "role": "athlete",
        "ironman_number": 0,
        "ironman_races_count": 0,
        "country_iso": "RU",
        "bio": null,
        "social_links": {
          "strava": null,
          "instagram": null,
          "facebook": null
        },
        "photos": {},
        "race_results": [],
        "stats": { ... }
      }
    },
    "token": "1|abc123xyz..."
  }
}
```

**Errors:**
```json
// 422 - email already taken
{
  "success": false,
  "errors": {
    "email": ["This email is already in use."]
  }
}
```

---

### 2.2 Login

```
POST /auth/login
```

**Access:** Public
**Description:** Authenticates the user. Revokes all previous tokens and creates a new one.

**Request body:**
```json
{
  "email": "ivan@example.com",
  "password": "SecurePass123!",
  "locale": "en"
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `email` | string | Yes | valid email |
| `password` | string | Yes | — |
| `locale` | string | No | `en`, `ru`, `az` — updates the user's language preference |

**Response 200:**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "user": {
      "id": 1,
      "name": "Ivan Petrov",
      "email": "ivan@example.com",
      "locale": "en",
      "verified": true,
      "profile": {
        "id": 1,
        "role": "athlete",
        "ironman_number": 123,
        "ironman_races_count": 5,
        "country_iso": "RU",
        "bio": "Triathlete since 2015",
        "social_links": {
          "strava": "https://strava.com/athletes/123",
          "instagram": "@ivan_tri",
          "facebook": null
        },
        "photos": {},
        "stats": { ... }
      }
    },
    "token": "2|def456uvw..."
  }
}
```

> **Note:** On login, the `race_results` field inside the profile is **not returned** (performance optimization). Use `GET /auth/user` or `GET /profiles/{id}/race-results` to retrieve results.

> **Security:** On invalid credentials, the same generic message is always returned (prevents email enumeration):

```json
// 401
{
  "success": false,
  "errors": {
    "email": ["Invalid email or password."]
  }
}
```

---

### 2.3 Logout

```
POST /auth/logout
```

**Access:** 🔒 Requires authentication
**Description:** Revokes the current access token.

**Response 200:**
```json
{
  "success": true,
  "message": "Logged out successfully."
}
```

---

### 2.4 Get Current User

```
GET /auth/user
```

**Access:** 🔒 Requires authentication
**Description:** Returns full data of the authenticated user, including profile and approved race results.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Ivan Petrov",
    "email": "ivan@example.com",
    "locale": "en",
    "verified": true,
    "profile": {
      "id": 1,
      "role": "athlete",
      "ironman_number": 123,
      "ironman_races_count": 5,
      "country_iso": "RU",
      "bio": "Triathlete since 2015",
      "social_links": {
        "strava": "https://strava.com/athletes/123",
        "instagram": "@ivan_tri",
        "facebook": null
      },
      "photos": {
        "0": {
          "id": 1,
          "url": "https://domain.com/storage/photos/abc.jpg",
          "filename": "abc.jpg",
          "is_avatar": false,
          "created_at": "2024-01-15T10:00:00.000000Z"
        }
      },
      "race_results": [
        {
          "id": 1,
          "name": "Ivan Petrov",
          "race_date": "2024-06-15",
          "location": "Baku, Azerbaijan",
          "race_type": "ironman",
          "race_type_label": "Ironman",
          "swim_time": "01:05:30",
          "t1_time": "00:03:00",
          "bike_time": "05:10:00",
          "t2_time": "00:02:00",
          "run_time": "03:45:00",
          "total_time": "10:05:30",
          "age_group": "M35-39",
          "overall_position": 42,
          "age_group_position": 5,
          "is_approved": true,
          "approved_at": "2024-06-20T09:00:00.000000Z"
        }
      ],
      "stats": {
        "total_races": 5,
        "best_ironman": "10:05:30",
        "best_ironman_70_3": "04:32:00"
      }
    }
  }
}
```

---

### 2.5 Resend Verification Email

```
POST /auth/email/resend-verification
```

**Access:** 🔒 Requires authentication

**Response 200:**
```json
{
  "success": true,
  "message": "Verification email sent."
}
```

**Error (email already verified):**
```json
{
  "success": false,
  "errors": {
    "email": ["Email is already verified."]
  }
}
```

---

### 2.6 Forgot Password

```
POST /auth/forgot-password
```

**Access:** Public
**Description:** Sends a password reset link. Always returns success regardless of whether the email exists (prevents email enumeration).

**Request body:**
```json
{
  "email": "ivan@example.com"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Password reset email sent."
}
```

---

### 2.7 Reset Password

```
POST /auth/reset-password
```

**Access:** Public

**Request body:**
```json
{
  "email": "ivan@example.com",
  "token": "abc123def456...",
  "password": "NewSecurePass123!",
  "password_confirmation": "NewSecurePass123!"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `email` | string | Yes | |
| `token` | string | Yes | Token from the reset link in the email |
| `password` | string | Yes | min 8 characters |
| `password_confirmation` | string | Yes | |

**Response 200:**
```json
{
  "success": true,
  "message": "Password has been reset successfully."
}
```

**Errors:**
```json
// 422 - invalid or expired token
{
  "success": false,
  "errors": {
    "token": ["The token is invalid or has expired."]
  }
}
```

---

### 2.8 Update User Locale

```
PUT /auth/locale
```

**Access:** 🔒 Requires authentication

**Request body:**
```json
{
  "locale": "en"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `locale` | string | Yes | `en`, `ru`, `az` |

**Response 200:**
```json
{
  "success": true,
  "message": "Language updated.",
  "data": {
    "locale": "en"
  }
}
```

---

## 3. User Profile

### 3.1 Get Profile

```
GET /user/profile
```

**Access:** 🔒 Requires authentication
**Description:** Returns the authenticated user's profile data (similar to `/auth/user`).

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Ivan Petrov",
    "email": "ivan@example.com",
    "locale": "en",
    "verified": true,
    "profile": { ... }
  }
}
```

---

### 3.2 Update Profile

```
PUT /user/profile
```

**Access:** 🔒 Requires authentication
**Description:** Updates user profile data. All fields are optional.

**Request body:**
```json
{
  "name": "Ivan Petrov",
  "ironman_number": 12345,
  "country_iso": "RU",
  "bio": "Triathlete since 2015. Love long distance.",
  "social_links": {
    "strava": "https://strava.com/athletes/123456",
    "instagram": "@ivan_triathlete",
    "facebook": "https://facebook.com/ivan"
  }
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `name` | string | No | max:255 |
| `ironman_number` | integer | No | nullable, min:1 |
| `country_iso` | string | No | nullable, 2 uppercase letters |
| `bio` | string | No | nullable, max:500 |
| `social_links` | object | No | nullable |
| `social_links.strava` | string | No | nullable, valid URL |
| `social_links.instagram` | string | No | nullable, max:255 |
| `social_links.facebook` | string | No | nullable, valid URL |

**Response 200:**
```json
{
  "success": true,
  "message": "Profile updated.",
  "data": {
    "profile": {
      "id": 1,
      "role": "athlete",
      "ironman_number": 12345,
      "ironman_races_count": 5,
      "country_iso": "RU",
      "bio": "Triathlete since 2015.",
      "social_links": {
        "strava": "https://strava.com/athletes/123456",
        "instagram": "@ivan_triathlete",
        "facebook": null
      },
      "photos": { ... },
      "stats": { ... }
    }
  }
}
```

---

### 3.3 Change Password

```
PUT /user/password
```

**Access:** 🔒 Requires authentication

**Request body:**
```json
{
  "current_password": "OldPass123!",
  "password": "NewPass456!",
  "password_confirmation": "NewPass456!"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Password changed successfully."
}
```

---

### 3.4 Create Profile (for profile selection screen)

```
POST /profiles/create
```

**Access:** 🔒 Requires authentication
**Description:** Creates a new empty athlete profile for a user who doesn't have one yet.

**Request body:** _none required_

**Response 201:**
```json
{
  "success": true,
  "message": "PROFILE_CREATED_SUCCESS",
  "data": {
    "profile": {
      "id": 5,
      "role": "athlete",
      "ironman_number": null,
      "ironman_races_count": 0,
      "country_iso": null,
      "bio": null,
      "social_links": {
        "strava": null,
        "instagram": null,
        "facebook": null
      },
      "photos": {}
    }
  }
}
```

**Error (profile already exists):**
```json
{
  "success": false,
  "errors": {
    "profile": ["PROFILE_ALREADY_EXISTS"]
  }
}
```

---

## 4. Photos

### 4.1 Get User Photos

```
GET /user/photos
```

**Access:** 🔒 Requires authentication

**Query parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `per_page` | integer | 15 | Items per page (1–50) |

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "url": "https://domain.com/storage/photos/abc.jpg",
      "filename": "abc.jpg",
      "is_avatar": true,
      "created_at": "2024-01-15T10:00:00.000000Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 15,
    "total": 3,
    "last_page": 1
  }
}
```

---

### 4.2 Upload Photos

```
POST /user/photos
```

**Access:** 🔒 Requires authentication
**Content-Type:** `multipart/form-data`

**Request body:**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `photos` | array | Yes | array of files, min:1, max:10 |
| `photos.*` | file | Yes | image, mimes: jpeg/png/jpg/webp, max 5MB per file |

**Response 201:**
```json
{
  "success": true,
  "data": {
    "photos": [
      {
        "id": 2,
        "url": "https://domain.com/storage/photos/xyz.jpg",
        "filename": "xyz.jpg",
        "is_avatar": false,
        "created_at": "2024-06-01T12:00:00.000000Z"
      }
    ]
  }
}
```

---

### 4.3 Set Photo as Avatar

```
POST /user/profile/avatar
```

**Access:** 🔒 Requires authentication

**Request body:**
```json
{
  "photo_id": 2
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "photo": {
      "id": 2,
      "url": "https://domain.com/storage/photos/xyz.jpg",
      "filename": "xyz.jpg",
      "is_avatar": true,
      "created_at": "2024-06-01T12:00:00.000000Z"
    }
  }
}
```

---

### 4.4 Delete Photo

```
DELETE /user/photos/{photoId}
```

**Access:** 🔒 Requires authentication

**Response 200:**
```json
{
  "success": true,
  "message": "Photo deleted."
}
```

**Error (photo not found or doesn't belong to the user):**
```json
{
  "success": false,
  "errors": {
    "photo_id": ["Photo not found or does not belong to you."]
  }
}
```

---

## 5. FCM Tokens

FCM (Firebase Cloud Messaging) tokens are used to send push notifications to mobile devices.

### 5.1 Register Token

```
POST /user/fcm-token
```

**Access:** 🔒 Requires authentication
**Description:** Registers or updates an FCM token. If the token already exists, it updates the user binding.

**Request body:**
```json
{
  "token": "fCm_TokEn_StRiNg_123...",
  "device_type": "android",
  "device_name": "Samsung Galaxy S23"
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `token` | string | Yes | max:500 |
| `device_type` | string | No | nullable, `android` or `ios` |
| `device_name` | string | No | nullable, max:255 |

**Response 201:**
```json
{
  "success": true,
  "message": "FCM token registered successfully.",
  "data": {
    "token": "fCm_TokEn_StRiNg_123...",
    "device_type": "android",
    "device_name": "Samsung Galaxy S23"
  }
}
```

---

### 5.2 Delete Token

```
DELETE /user/fcm-token
```

**Access:** 🔒 Requires authentication
**Description:** Deletes an FCM token (on logout, app uninstall, or token refresh).

**Request body:**
```json
{
  "token": "fCm_TokEn_StRiNg_123..."
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "FCM token deleted successfully."
}
```

**Error:**
```json
{
  "success": false,
  "errors": {
    "token": ["FCM token not found or does not belong to you."]
  }
}
```

---

## 6. Notifications

### 6.1 List Notifications

```
GET /notifications
```

**Access:** 🔒 Requires authentication

**Query parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `per_page` | integer | 15 | Items per page (1–50) |

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Result approved",
      "body": "Your race result has been approved by the administrator.",
      "translations": {
        "en": {
          "title": "Result approved",
          "body": "Your race result has been approved by the administrator."
        },
        "ru": {
          "title": "Результат одобрен",
          "body": "Ваш результат гонки был одобрен администратором."
        }
      },
      "type": "race_approved",
      "data": {
        "race_result_id": 42
      },
      "read_at": null,
      "is_read": false,
      "created_at": "2024-06-20T09:00:00+00:00"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 5,
    "last_page": 1,
    "unread_count": 3
  }
}
```

**Notification types (`type`):**

| Type | Description |
|------|-------------|
| `race_approved` | Race result approved |
| `race_rejected` | Race result rejected |
| `profile_synced` | Profile linked to account |
| `transfer_approved` | Result transfer approved |
| `transfer_rejected` | Result transfer rejected |
| `system` | System notification |

---

### 6.2 Mark Notification as Read

```
POST /notifications/{id}/read
```

**Access:** 🔒 Requires authentication

**Response 200:**
```json
{
  "success": true,
  "message": "Notification marked as read.",
  "data": {
    "id": 1,
    "title": "Result approved",
    "body": "...",
    "translations": { ... },
    "type": "race_approved",
    "data": { ... },
    "read_at": "2024-06-21T10:00:00+00:00",
    "is_read": true,
    "created_at": "2024-06-20T09:00:00+00:00"
  }
}
```

---

### 6.3 Mark All Notifications as Read

```
POST /notifications/read-all
```

**Access:** 🔒 Requires authentication

**Response 200:**
```json
{
  "success": true,
  "message": "All notifications marked as read (3).",
  "data": {
    "marked_count": 3
  }
}
```

---

### 6.4 Delete Notification

```
DELETE /notifications/{id}
```

**Access:** 🔒 Requires authentication

**Response 200:**
```json
{
  "success": true,
  "message": "Notification deleted."
}
```

---

## 7. Athletes

Public endpoints for browsing athlete profiles. Throttle: 60 requests/min.

### 7.1 List Athletes

```
GET /athletes
```

**Access:** Public

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Ivan Petrov",
      "avatar": "https://domain.com/storage/photos/avatar.jpg",
      "country_iso": "RU",
      "race_counts": {
        "ironman": 5,
        "ironman_70_3": 3,
        "5150": 2
      }
    }
  ]
}
```

> **Note:** Only athletes (role = `athlete`) with `results_transferred = false` are returned.

---

### 7.2 Athlete Profile

```
GET /athletes/{id}
```

**Access:** Public

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Ivan Petrov",
    "avatar": "https://domain.com/storage/photos/avatar.jpg",
    "country_iso": "RU",
    "race_counts": {
      "ironman": 5,
      "ironman_70_3": 3,
      "5150": 2
    },
    "ironman_number": 12345,
    "bio": "Triathlete since 2015.",
    "social_links": {
      "strava": "https://strava.com/athletes/123",
      "instagram": "@ivan_tri",
      "facebook": null
    },
    "ranking": {
      "ironman": {
        "position": 3,
        "total": 45
      },
      "ironman_70_3": {
        "position": 7,
        "total": 38
      }
    }
  }
}
```

**Error 404:**
```json
{
  "success": false,
  "errors": {
    "athlete": ["Athlete not found."]
  }
}
```

---

### 7.3 Athlete Personal Records

```
GET /athletes/{id}/records
```

**Access:** Public
**Description:** Returns the best result per discipline for each race type.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "ironman": {
      "swim": {
        "time": "01:05:30",
        "seconds": 3930,
        "race_date": "2024-06-15",
        "location": "Baku, Azerbaijan"
      },
      "t1": {
        "time": "00:03:00",
        "seconds": 180,
        "race_date": "2024-06-15",
        "location": "Baku, Azerbaijan"
      },
      "bike": {
        "time": "05:10:00",
        "seconds": 18600,
        "race_date": "2024-06-15",
        "location": "Baku, Azerbaijan"
      },
      "t2": {
        "time": "00:02:00",
        "seconds": 120,
        "race_date": "2024-06-15",
        "location": "Baku, Azerbaijan"
      },
      "run": {
        "time": "03:45:00",
        "seconds": 13500,
        "race_date": "2024-06-15",
        "location": "Baku, Azerbaijan"
      },
      "total": {
        "time": "10:05:30",
        "seconds": 36330,
        "race_date": "2024-06-15",
        "location": "Baku, Azerbaijan"
      }
    },
    "ironman_70_3": {
      "swim": null,
      "t1": null,
      "bike": null,
      "t2": null,
      "run": null,
      "total": null
    },
    "5150": {
      "swim": null,
      "t1": null,
      "bike": null,
      "t2": null,
      "run": null,
      "total": null
    }
  }
}
```

> `null` means the athlete has no approved results with complete data for that discipline and race type.

---

### 7.4 Athlete Photos

```
GET /athletes/{id}/photos
```

**Access:** Public

**Query parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `per_page` | integer | 15 | Items per page (1–50) |

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "url": "https://domain.com/storage/photos/abc.jpg",
      "filename": "abc.jpg",
      "is_avatar": false,
      "created_at": "2024-06-01T12:00:00.000000Z"
    }
  ],
  "has_photos": true,
  "pagination": {
    "current_page": 1,
    "per_page": 15,
    "total": 10,
    "last_page": 1
  }
}
```

> If the athlete has no linked user account (donor athlete), an empty list with `has_photos: false` is returned.

---

## 8. Rankings

### 8.1 Leaderboard

```
GET /rankings
```

**Access:** Public. Throttle: 60 requests/min.
**Description:** Returns athlete rankings by race type and discipline. Rankings are based on each athlete's personal best time. Only **approved** results with **complete data** (all times > 0) are counted.

**Query parameters:**

| Parameter | Type | Required | Values |
|-----------|------|----------|--------|
| `race_type` | string | Yes | `ironman`, `ironman_70_3`, `5150` |
| `discipline` | string | Yes | `swim`, `bike`, `run`, `total` |

**Example:**
```
GET /rankings?race_type=ironman&discipline=total
```

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "position": 1,
      "athlete_id": 5,
      "name": "Alexei Sidorov",
      "avatar": "https://domain.com/storage/photos/avatar.jpg",
      "time": "08:42:15",
      "seconds": 31335,
      "race_date": "2023-09-10",
      "location": "Zurich, Switzerland"
    },
    {
      "position": 2,
      "athlete_id": 1,
      "name": "Ivan Petrov",
      "avatar": null,
      "time": "10:05:30",
      "seconds": 36330,
      "race_date": "2024-06-15",
      "location": "Baku, Azerbaijan"
    }
  ],
  "meta": {
    "race_type": "ironman",
    "discipline": "total",
    "total": 45
  }
}
```

**Errors:**
```json
// 422 - invalid race_type
{
  "success": false,
  "errors": {
    "race_type": ["Invalid race type. Allowed: ironman, ironman_70_3, 5150"]
  }
}

// 422 - invalid discipline
{
  "success": false,
  "errors": {
    "discipline": ["Invalid discipline. Allowed: swim, bike, run, total"]
  }
}
```

---

## 9. Races

### 9.1 List Races

```
GET /races
```

**Access:** 🔒 Requires authentication
**Description:** Returns a list of active races. Excludes races the user has already added to their upcoming races (`upcoming_races`).

**Query parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `search` | string | Search by location name |
| `type` | string | Race type: `ironman`, `ironman_70_3`, `5150` |
| `country` | string | Country code (ISO 2 letters) |
| `date_from` | date | Range start date (YYYY-MM-DD) |
| `date_to` | date | Range end date (YYYY-MM-DD) |

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "date": "2024-09-15",
      "location": "Nice, France",
      "type": "ironman",
      "type_label": "Ironman",
      "country_iso": "FR"
    },
    {
      "id": 11,
      "date": "2024-10-20",
      "location": "Gdansk, Poland",
      "type": "ironman_70_3",
      "type_label": "Ironman 70.3",
      "country_iso": "PL"
    }
  ]
}
```

---

## 10. Upcoming Races

### 10.1 List Upcoming Races

```
GET /upcoming-races
```

**Access:** Public. Throttle: 60 requests/min.

**Query parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `only_future` | boolean | `true` | `true` — future races only, `false` — all |
| `user_profile_id` | integer | — | Filter by athlete profile ID |
| `race_type` | string | — | Race type: `ironman`, `ironman_70_3`, `5150` |
| `per_page` | integer | 15 | Items per page (max 100) |

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "race_type": "ironman",
      "race_type_label": "Ironman",
      "location": "Nice, France",
      "country_iso": "FR",
      "race_date": "2024-09-15T00:00:00.000000Z",
      "is_active": true,
      "created_by": {
        "id": 1,
        "name": "Ivan Petrov",
        "avatar": "https://domain.com/storage/photos/avatar.jpg"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 15,
    "total": 42
  }
}
```

---

### 10.2 Add Upcoming Race

```
POST /upcoming-races
```

**Access:** 🔒 Requires authentication
**Description:** Adds a race from the catalog to the user's upcoming races list. Each user can add a race only once.

**Request body:**
```json
{
  "race_id": 10
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `race_id` | integer | Yes | existing race, not previously added |

**Response 201:**
```json
{
  "success": true,
  "message": "Upcoming race added.",
  "data": {
    "id": 5,
    "race_type": "ironman",
    "race_type_label": "Ironman",
    "location": "Nice, France",
    "country_iso": "FR",
    "race_date": "2024-09-15T00:00:00.000000Z",
    "is_active": true,
    "created_by": {
      "id": 1,
      "name": "Ivan Petrov",
      "avatar": null
    }
  }
}
```

---

## 11. Race Results

### 11.1 List All Results (paginated)

```
GET /race-results
```

**Access:** Public
**Description:** Returns approved race results for all athletes. Sorted by date (newest first). Page size: 15.

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_profile_id": 1,
      "name": "Ivan Petrov",
      "race_date": "2024-06-15",
      "location": "Baku, Azerbaijan",
      "race_type": "ironman",
      "race_type_label": "Ironman",
      "swim_time": "01:05:30",
      "t1_time": "00:03:00",
      "bike_time": "05:10:00",
      "t2_time": "00:02:00",
      "run_time": "03:45:00",
      "total_time": "10:05:30",
      "age_group": "M35-39",
      "overall_position": 42,
      "age_group_position": 5,
      "is_approved": true,
      "approved_at": "2024-06-20T09:00:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 73
  }
}
```

---

### 11.2 Single Race Result

```
GET /race-results/{id}
```

**Access:** Public
**Description:** Returns a single approved race result.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_profile_id": 1,
    "name": "Ivan Petrov",
    ...
  }
}
```

**Error 404** (if result is not approved or not found):
```json
{
  "success": false,
  "errors": {
    "message": ["Result not found or not yet approved."]
  }
}
```

---

### 11.3 Results for a Specific Profile

```
GET /profiles/{userProfileId}/race-results
```

**Access:** Public
**Description:** Returns approved race results for a specific athlete profile. The `user_profile_id` field is excluded from the response.

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Ivan Petrov",
      "race_date": "2024-06-15",
      "location": "Baku, Azerbaijan",
      "race_type": "ironman",
      "race_type_label": "Ironman",
      "swim_time": "01:05:30",
      "t1_time": "00:03:00",
      "bike_time": "05:10:00",
      "t2_time": "00:02:00",
      "run_time": "03:45:00",
      "total_time": "10:05:30",
      "age_group": "M35-39",
      "overall_position": 42,
      "age_group_position": 5,
      "is_approved": true,
      "approved_at": "2024-06-20T09:00:00.000000Z"
    }
  ]
}
```

---

### 11.4 Submit Race Result

```
POST /race-results
```

**Access:** 🔒 Requires authentication
**Description:** Creates a new race result. The result is submitted for moderation (`is_approved = false`). An admin notification is triggered upon creation.

**Request body:**
```json
{
  "race_date": "2024-06-15",
  "location": "Baku, Azerbaijan",
  "race_type": "ironman",
  "swim_time": 3930,
  "t1_time": 180,
  "bike_time": 18600,
  "t2_time": 120,
  "run_time": 13500,
  "total_time": 36330,
  "age_group": "M35-39",
  "overall_position": 42,
  "age_group_position": 5
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `race_date` | date | Yes | format YYYY-MM-DD |
| `location` | string | Yes | max:255 |
| `race_type` | string | Yes | `ironman`, `ironman_70_3`, `5150` |
| `swim_time` | integer | Yes | seconds, min:0 |
| `t1_time` | integer | Yes | seconds, min:0 |
| `bike_time` | integer | Yes | seconds, min:0 |
| `t2_time` | integer | Yes | seconds, min:0 |
| `run_time` | integer | Yes | seconds, min:0 |
| `total_time` | integer | Yes | seconds, min:0 |
| `age_group` | string | No | nullable, max:20 (e.g. `M35-39`, `F25-29`) |
| `overall_position` | integer | No | nullable, min:1 |
| `age_group_position` | integer | No | nullable, min:1 |

**Response 201:**
```json
{
  "success": true,
  "message": "Result submitted for review.",
  "data": {
    "id": 10,
    "user_profile_id": 1,
    "name": "Ivan Petrov",
    "race_date": "2024-06-15",
    "location": "Baku, Azerbaijan",
    "race_type": "ironman",
    "race_type_label": "Ironman",
    "swim_time": "01:05:30",
    "t1_time": "00:03:00",
    "bike_time": "05:10:00",
    "t2_time": "00:02:00",
    "run_time": "03:45:00",
    "total_time": "10:05:30",
    "age_group": "M35-39",
    "overall_position": 42,
    "age_group_position": 5,
    "is_approved": false,
    "approved_at": null
  }
}
```

---

### 11.5 Update Race Result

```
PUT /race-results/{id}
```

**Access:** 🔒 Requires authentication
**Description:** Updates an existing race result. Only accessible for results belonging to the current user.

**Request body:** Same fields as when creating (all optional).

**Response 200:**
```json
{
  "success": true,
  "data": { ... }
}
```

---

### 11.6 Delete Race Result

```
DELETE /race-results/{id}
```

**Access:** 🔒 Requires authentication
**Description:** Deletes a race result. Only accessible for unapproved results belonging to the current user.

**Response 200:**
```json
{
  "success": true,
  "message": "Result deleted."
}
```

---

## 12. Result Transfer

This feature allows a user to "claim" the results of another athlete (a donor). The request goes through admin moderation.

### 12.1 List Eligible Athletes for Transfer

```
GET /transfer/eligible-athletes
```

**Access:** 🔒 Requires authentication
**Description:** Returns athletes who have no linked user account and whose results are available for transfer.

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 3,
      "name": "Alexei Donor",
      "avatar": null,
      "country_iso": "RU",
      "ironman_number": 999,
      "race_counts": {
        "ironman": 3,
        "ironman_70_3": 1,
        "5150": 0
      },
      "total_races": 4
    }
  ]
}
```

---

### 12.2 Submit Transfer Request

```
POST /transfer/request
```

**Access:** 🔒 Requires authentication

**Request body:**
```json
{
  "source_athlete_id": 3
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `source_athlete_id` | integer | Yes | existing profile ID |

**Response 201:**
```json
{
  "success": true,
  "message": "Result transfer request created.",
  "data": {
    "id": 1,
    "source_athlete_id": 3,
    "status": "pending",
    "created_at": "2024-06-21T10:00:00.000000Z"
  }
}
```

**Request statuses:**

| Status | Description |
|--------|-------------|
| `pending` | Awaiting review |
| `approved` | Approved |
| `rejected` | Rejected |

---

### 12.3 Get Current Transfer Request

```
GET /transfer/current
```

**Access:** 🔒 Requires authentication
**Description:** Returns the most recent transfer request for the current user.

**Response 200 (request exists):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "source_athlete": {
      "id": 3,
      "name": "Alexei Donor"
    },
    "status": "approved",
    "status_label": "Approved",
    "comment": "Data matches.",
    "reviewed_by": "Admin User",
    "reviewed_at": "2024-06-22T09:00:00.000000Z",
    "created_at": "2024-06-21T10:00:00.000000Z"
  }
}
```

**Response 200 (no requests):**
```json
{
  "success": true,
  "data": null,
  "message": "No transfer requests found."
}
```

---

## 13. Policies & Documents

### 13.1 List Policy Types

```
GET /policies/types
```

**Access:** Public. Throttle: 60 requests/min.

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "type": "privacy_policy",
      "name": "Privacy Policy"
    },
    {
      "type": "terms_of_service",
      "name": "Terms of Service"
    }
  ]
}
```

---

### 13.2 Available Languages for Policies

```
GET /policies/languages
```

**Access:** Public. Throttle: 60 requests/min.

**Response 200:**
```json
{
  "success": true,
  "data": [
    { "code": "en", "name": "English" },
    { "code": "ru", "name": "Русский" },
    { "code": "az", "name": "Azərbaycan" }
  ]
}
```

---

### 13.3 Get Policy by Type

```
GET /policies/{type}
```

**Access:** Public. Throttle: 60 requests/min.
**Description:** Returns the latest active version of a policy. Language is determined automatically (from the token, header, or `locale` parameter).

**Path parameter `{type}`:** `privacy_policy`, `terms_of_service` (and other types from `/policies/types`)

**Query parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `locale` | string | Force a specific language: `en`, `ru`, `az` |

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "type": "privacy_policy",
    "type_name": "Privacy Policy",
    "language": "en",
    "title": "Privacy Policy",
    "content": "Full text of the privacy policy...",
    "is_active": true,
    "effective_date": "2024-01-01T00:00:00.000000Z",
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

**Errors:**
```json
// 400 - invalid type
{
  "success": false,
  "errors": {
    "type": ["Invalid policy type."]
  }
}

// 404 - policy not found
{
  "success": false,
  "errors": {
    "policy": ["Policy not found."]
  }
}
```

---

## 14. Admin Panel

> All endpoints are accessible only for users with the `admin` role (`profile.role = 'admin'`). Returns 403 if insufficient permissions.

### 14.1 Link Profile to User

```
POST /admin/users/{userId}/link-profile/{profileId}
```

**Access:** 🔒 Requires authentication + `admin` role

**Response 200:**
```json
{
  "success": true,
  "message": "Profile successfully linked to user.",
  "data": {
    "user": {
      "id": 2,
      "name": "New User",
      "email": "user@example.com"
    },
    "profile": {
      "id": 3,
      "role": "athlete",
      "ironman_number": 999
    }
  }
}
```

**Errors:**
```json
// 403 - not an admin
{
  "success": false,
  "errors": {
    "message": ["Access denied. Administrator rights required."]
  }
}

// 422 - profile already linked to another user
{
  "success": false,
  "errors": {
    "profile": ["This profile is already linked to another user."]
  }
}
```

---

### 14.2 List Pending Race Results

```
GET /admin/race-results/pending
```

**Access:** 🔒 Requires authentication + `admin` role
**Description:** Returns race results awaiting approval (`is_approved = false`), sorted by creation date.

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "user_profile_id": 1,
      "name": "Ivan Petrov",
      "race_date": "2024-06-15",
      "location": "Baku, Azerbaijan",
      "race_type": "ironman",
      "race_type_label": "Ironman",
      "swim_time": "01:05:30",
      "t1_time": "00:03:00",
      "bike_time": "05:10:00",
      "t2_time": "00:02:00",
      "run_time": "03:45:00",
      "total_time": "10:05:30",
      "age_group": "M35-39",
      "overall_position": 42,
      "age_group_position": 5,
      "is_approved": false,
      "approved_at": null
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 3
  }
}
```

---

### 14.3 Approve Race Result

```
POST /admin/race-results/{id}/approve
```

**Access:** 🔒 Requires authentication + `admin` role
**Description:** Approves a race result. Sends a push notification to the athlete.

**Response 200:**
```json
{
  "success": true,
  "message": "Result approved successfully.",
  "data": {
    "id": 10,
    "is_approved": true,
    "approved_at": "2024-06-20T09:00:00.000000Z",
    "approved_by": {
      "id": 99,
      "name": "Admin User"
    },
    ...
  }
}
```

---

### 14.4 Reject Race Result

```
DELETE /admin/race-results/{id}/reject
```

**Access:** 🔒 Requires authentication + `admin` role
**Description:** Rejects and **permanently deletes** a race result. Cannot reject an already approved result.

**Response 200:**
```json
{
  "success": true,
  "message": "Result rejected and deleted."
}
```

**Error (result already approved):**
```json
{
  "success": false,
  "errors": {
    "message": ["Cannot reject an already approved result."]
  }
}
```

---

## Appendix A. `UserProfile` Object Structure

```json
{
  "id": 1,
  "role": "athlete",
  "ironman_number": 12345,
  "ironman_races_count": 5,
  "country_iso": "RU",
  "bio": "Biography text",
  "social_links": {
    "strava": "https://strava.com/athletes/123",
    "instagram": "@handle",
    "facebook": "https://facebook.com/user"
  },
  "photos": {
    "0": {
      "id": 1,
      "url": "https://domain.com/storage/photos/abc.jpg",
      "filename": "abc.jpg",
      "is_avatar": true,
      "created_at": "2024-01-15T10:00:00.000000Z"
    }
  },
  "race_results": [ ... ],
  "stats": {
    "total_races": 8,
    "best_ironman": "10:05:30",
    "best_ironman_70_3": "04:32:00"
  }
}
```

> **Important:** `photos` is an **object**, not an array. When there are no photos, it returns `{}` (empty object). This behavior is specific to the mobile client.

---

## Appendix B. Email Verification Flow

On login (`POST /auth/login`), if the email is not verified, the response remains `200 OK` but the message changes:

```json
{
  "success": true,
  "message": "Email not verified. Please verify your email for full access.",
  "data": {
    "user": { ... },
    "token": "..."
  }
}
```

> A token is issued, but it is recommended to restrict access on the client side until the email is verified.

---

## Appendix C. Email Verification (Web Route)

```
GET /verify-email/{id}/{hash}
```

**Type:** Web route (not API), returns an HTML page.
The link is generated automatically and sent to the user's email.

---

*Documentation is current for API v1. Last updated: 2026-03-05.*
