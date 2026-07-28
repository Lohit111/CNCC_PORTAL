# CNCC Portal - Model Summary

## Enums (`models/enums.py`)

### `UserRole`

| Value   | Description                        |
| ------- | ---------------------------------- |
| `USER`  | Regular user raising requests      |
| `ADMIN` | Administrator managing requests    |
| `STAFF` | Staff member assigned to requests  |
| `STORE` | Store user handling store requests |

### `RequestStatus`

| Value                |
| -------------------- |
| `RAISED`             |
| `REPLIED`            |
| `ASSIGNED`           |
| `IN_PROGRESS`        |
| `REASSIGN_REQUESTED` |
| `COMPLETED`          |
| `REJECTED`           |

### `TrackEventType`

| Value                     |
| ------------------------- |
| `RAISED`                  |
| `ASSIGNED`                |
| `IN_PROGRESS`             |
| `REASSIGN_REQUESTED`      |
| `COMPLETED`               |
| `REJECTED`                |
| `STORE_REQUEST_CREATED`   |
| `STORE_REQUEST_APPROVED`  |
| `STORE_REQUEST_REJECTED`  |
| `STORE_REQUEST_FULFILLED` |
| `REPLIED`                 |

### `StoreRequestStatus`

| Value       |
| ----------- |
| `PENDING`   |
| `APPROVED`  |
| `REJECTED`  |
| `FULFILLED` |

---

## Tables

### `users`

| Column       | Type           | Constraints            |
| ------------ | -------------- | ---------------------- |
| `id`         | String (UUID)  | PK, auto-generated     |
| `email`      | String         | unique, not null       |
| `name`       | String         | nullable               |
| `role`       | Enum(UserRole) | not null               |
| `is_active`  | Boolean        | not null, default=true |
| `created_at` | DateTime       | not null, default=now  |

**Relationships**

- → `requests` (raised_requests) via `requests.raised_by`
- → `request_tracks` (tracks) via `request_tracks.performed_by`
- → `assignments` via `assignments.staff_id`
- → `store_requests` (store_requests) via `store_requests.requested_by`
- → `store_requests` (responded_store_requests) via `store_requests.responded_by`
- → `store_chats` via `store_chats.sender_id`

---

### `main_types`

| Column | Type    | Constraints      |
| ------ | ------- | ---------------- |
| `id`   | Integer | PK               |
| `name` | String  | unique, not null |

**Relationships**

- → `sub_types` (cascade delete-orphan)

---

### `sub_types`

| Column         | Type    | Constraints                    |
| -------------- | ------- | ------------------------------ |
| `id`           | Integer | PK                             |
| `name`         | String  | not null                       |
| `main_type_id` | Integer | FK → `main_types.id`, not null |

**Relationships**

- → `main_types`

---

### `requests`

| Column        | Type                | Constraints                         |
| ------------- | ------------------- | ----------------------------------- |
| `id`          | String (UUID)       | PK                                  |
| `raised_by`   | String              | FK → `users.id`, not null           |
| `main_type`   | String              | not null (snapshot at creation)     |
| `sub_type`    | String              | not null (snapshot at creation)     |
| `description` | Text                | not null                            |
| `room_no`     | String              | not null                            |
| `phone_no`    | String(10)          | not null                            |
| `status`      | Enum(RequestStatus) | not null                            |
| `created_at`  | DateTime            | not null, default=now               |
| `updated_at`  | DateTime            | not null, default=now, onupdate=now |

**Relationships**

- → `users` (raiser)
- → `request_tracks` (cascade delete-orphan)
- → `assignments` (cascade delete-orphan)
- → `store_requests` (cascade delete-orphan)

---

### `request_tracks`

| Column              | Type                 | Constraints                        |
| ------------------- | -------------------- | ---------------------------------- |
| `id`                | Integer              | PK                                 |
| `request_id`        | String               | FK → `requests.id`, not null       |
| `store_request_id`  | String               | FK → `store_requests.id`, nullable |
| `event_type`        | Enum(TrackEventType) | not null                           |
| `performed_by`      | String               | FK → `users.id`, not null          |
| `performed_by_role` | Enum(UserRole)       | not null                           |
| `comment`           | Text                 | nullable                           |
| `created_at`        | DateTime             | not null, default=now              |

**Relationships**

- → `requests`
- → `store_requests`
- → `users` (performer)
- → `assignments`

---

### `assignments`

| Column       | Type     | Constraints                        |
| ------------ | -------- | ---------------------------------- |
| `id`         | Integer  | PK                                 |
| `request_id` | String   | FK → `requests.id`, not null       |
| `staff_id`   | String   | FK → `users.id`, not null          |
| `track_id`   | Integer  | FK → `request_tracks.id`, not null |
| `created_at` | DateTime | not null, default=now              |

**Purpose**: Groups multiple staff assignments under a single `ASSIGNED` status change track entry.

**Relationships**

- → `requests`
- → `users` (staff)
- → `request_tracks` (track)

---

### `store_requests`

| Column              | Type                     | Constraints                         |
| ------------------- | ------------------------ | ----------------------------------- |
| `id`                | String (UUID)            | PK                                  |
| `parent_request_id` | String                   | FK → `requests.id`, not null        |
| `requested_by`      | String                   | FK → `users.id`, not null           |
| `description`       | Text                     | not null                            |
| `status`            | Enum(StoreRequestStatus) | not null                            |
| `responded_by`      | String                   | FK → `users.id`, nullable           |
| `created_at`        | DateTime                 | not null, default=now               |
| `updated_at`        | DateTime                 | not null, default=now, onupdate=now |

**Relationships**

- → `requests` (parent_request)
- → `users` (requester) via `requested_by`
- → `users` (responder) via `responded_by`
- → `request_tracks` (cascade delete-orphan)
- → `store_chats` (cascade delete-orphan)

---

### `store_chats`

| Column             | Type     | Constraints                        |
| ------------------ | -------- | ---------------------------------- |
| `id`               | Integer  | PK                                 |
| `store_request_id` | String   | FK → `store_requests.id`, not null |
| `sender_id`        | String   | FK → `users.id`, not null          |
| `message`          | Text     | not null                           |
| `created_at`       | DateTime | not null, default=now              |

**Relationships**

- → `store_requests`
- → `users` (sender)

---

# API Reference

All endpoints are prefixed with `/api/v1`. Authentication is via Firebase Bearer token in the `Authorization` header.

## Response Shape — Request Detail

Most GET endpoints return individual requests in this shape:

```json
{
  "request": { ... },
  "timeline": [ ... ],
  "assignments": [ ... ],
  "store_requests": [ ... ],
  "users": { "uid": { user document } }
}
```

## Response Shape — Store Request Detail

Store endpoints return items in this shape:

```json
{
  "store_request": { ... },
  "parent_request": {
    "request": { ... },
    "timeline": [ ... ],
    "assignments": [ ... ],
    "users": { "uid": { user document } }
  }
}
```

## Pagination

All list endpoints accept a `page` query parameter (default: 1).

- User lists: 50 per page
- All others: 30 per page

Response shape:

```json
{ "requests": [...], "total": 120, "page": 2, "pages": 4 }
```

---

## Users `/users`

| Method   | Path                           | Auth  | Description                               |
| -------- | ------------------------------ | ----- | ----------------------------------------- |
| `GET`    | `/users/me`                    | Any   | Get current authenticated user            |
| `PUT`    | `/users/me/name`               | Any   | Update current user's name                |
| `GET`    | `/users/?page=`                | ADMIN | Get all active users (50/page)            |
| `POST`   | `/users/`                      | ADMIN | Create a user                             |
| `PUT`    | `/users/{user_id}/update-role` | ADMIN | Update a user's role                      |
| `DELETE` | `/users/{user_id}`             | ADMIN | Soft-delete a user (sets is_active=false) |

**POST /users/ body:**

```json
{ "email": "user@vnrvjiet.in", "role": "STAFF" }
```

**PUT /users/{id}/update-role body:**

```json
{ "role": "ADMIN" }
```

**PUT /users/me/name body:**

```json
{ "name": "John Doe" }
```

---

## Types `/types`

| Method   | Path                    | Auth  | Description                              |
| -------- | ----------------------- | ----- | ---------------------------------------- |
| `GET`    | `/types/main`           | Any   | Get all main types                       |
| `GET`    | `/types/{main_id}/sub`  | Any   | Get sub types for a main type            |
| `POST`   | `/types/main`           | ADMIN | Create a main type                       |
| `POST`   | `/types/{main_id}/sub`  | ADMIN | Create a sub type                        |
| `PUT`    | `/types/main/{main_id}` | ADMIN | Update main type name                    |
| `PUT`    | `/types/sub/{sub_id}`   | ADMIN | Update sub type name                     |
| `DELETE` | `/types/main/{main_id}` | ADMIN | Delete main type (cascades to sub types) |
| `DELETE` | `/types/sub/{sub_id}`   | ADMIN | Delete sub type                          |

**POST body (all create/update):**

```json
{ "name": "Electrical" }
```

---

## My Requests `/my-requests`

Restricted to: `USER`, `ADMIN`, `STAFF`

| Method | Path                              | Auth             | Description                                            |
| ------ | --------------------------------- | ---------------- | ------------------------------------------------------ |
| `POST` | `/my-requests/`                   | USER/ADMIN/STAFF | Raise a new request                                    |
| `GET`  | `/my-requests/raised?page=`       | USER/ADMIN/STAFF | My requests in RAISED status                           |
| `GET`  | `/my-requests/replied?page=`      | USER/ADMIN/STAFF | My requests in REPLIED status                          |
| `GET`  | `/my-requests/inprogress?page=`   | USER/ADMIN/STAFF | My requests in ASSIGNED/IN_PROGRESS/REASSIGN_REQUESTED |
| `GET`  | `/my-requests/archive?page=`      | USER/ADMIN/STAFF | My requests in COMPLETED/REJECTED                      |
| `PUT`  | `/my-requests/reply/{request_id}` | USER/ADMIN/STAFF | Reply to admin on a REPLIED request                    |

**POST /my-requests/ body:**

```json
{
  "main_type": "Electrical",
  "sub_type": "Lighting",
  "description": "Ceiling light not working in room 204",
  "room_no": "204",
  "phone_no": "9876543210"
}
```

Creates request with `RAISED` status and an initial `RAISED` track entry.

**PUT /my-requests/reply/{request_id} body:**

```json
{
  "comment": "Here is the updated info",
  "description": "Updated description of the issue"
}
```

Sets request status back to `RAISED` and updates the description.

---

## Admin `/admin`

Restricted to: `ADMIN`

### GET Endpoints

| Method | Path                              | Description                     |
| ------ | --------------------------------- | ------------------------------- |
| `GET`  | `/admin/raised?page=`             | All RAISED requests             |
| `GET`  | `/admin/replied?page=`            | All REPLIED requests            |
| `GET`  | `/admin/assigned?page=`           | All ASSIGNED requests           |
| `GET`  | `/admin/reassign-requested?page=` | All REASSIGN_REQUESTED requests |
| `GET`  | `/admin/inprogress?page=`         | All IN_PROGRESS requests        |
| `GET`  | `/admin/archive?page=`            | All COMPLETED/REJECTED requests |

### Action Endpoints

| Method   | Path                                      | Description                                          |
| -------- | ----------------------------------------- | ---------------------------------------------------- |
| `PUT`    | `/admin/reply/{request_id}`               | Set status → REPLIED, create track                   |
| `PUT`    | `/admin/assign/{request_id}`              | Assign to staff, set status → ASSIGNED, create track |
| `PUT`    | `/admin/reject/{request_id}`              | Set status → REJECTED, create track                  |
| `DELETE` | `/admin/request/{request_id}`             | Delete request and all related data                  |
| `DELETE` | `/admin/store-request/{store_request_id}` | Delete store request and chats                       |

**PUT /admin/reply/{id} body:**

```json
{ "comment": "Please provide more details about the issue" }
```

**PUT /admin/assign/{id} body:**

```json
{ "staff_ids": ["uid1", "uid2"] }
```

**PUT /admin/reject/{id} body:**

```json
{ "comment": "Request outside scope of service" }
```

---

## Staff `/staff`

Restricted to: `STAFF`

### GET Endpoints

| Method | Path                             | Description                                     |
| ------ | -------------------------------- | ----------------------------------------------- |
| `GET`  | `/staff/assigned?page=`          | Requests actively assigned to this staff        |
| `GET`  | `/staff/inprogress?page=`        | In-progress requests taken by this staff        |
| `GET`  | `/staff/archive?page=`           | Completed/rejected requests this staff finished |
| `GET`  | `/staff/chat/{store_request_id}` | Get all chat messages for a store request       |

### Action Endpoints

| Method | Path                                       | Description                                                           |
| ------ | ------------------------------------------ | --------------------------------------------------------------------- |
| `PUT`  | `/staff/start-request/{request_id}`        | Set status → IN_PROGRESS, create track                                |
| `PUT`  | `/staff/request-reassignment/{request_id}` | Set status → REASSIGN_REQUESTED, deactivate assignments, create track |
| `PUT`  | `/staff/finish-request/{request_id}`       | Set status → COMPLETED, deactivate assignments, create track          |
| `PUT`  | `/staff/create-store-request/{request_id}` | Create store request with PENDING status, create track                |

**PUT /staff/request-reassignment/{id} body:**

```json
{ "comment": "Requires specialist equipment I don't have access to" }
```

**PUT /staff/create-store-request/{id} body:**

```json
{ "description": "Need 2x replacement light fittings, model XYZ-100" }
```

---

## Store `/store`

Restricted to: `STORE`

### GET Endpoints

| Method | Path                    | Description                                |
| ------ | ----------------------- | ------------------------------------------ |
| `GET`  | `/store/pending?page=`  | All PENDING store requests                 |
| `GET`  | `/store/approved?page=` | Store requests approved by this store user |
| `GET`  | `/store/archive?page=`  | All REJECTED/FULFILLED store requests      |

### Action Endpoints

| Method | Path                                | Description                                        |
| ------ | ----------------------------------- | -------------------------------------------------- |
| `PUT`  | `/store/approve/{store_request_id}` | Set store request status → APPROVED, create track  |
| `PUT`  | `/store/reject/{store_request_id}`  | Set store request status → REJECTED, create track  |
| `PUT`  | `/store/fulfil/{store_request_id}`  | Set store request status → FULFILLED, create track |
| `POST` | `/store/chat/{store_request_id}`    | Send a chat message                                |

**PUT /store/reject/{id} body:**

```json
{ "comment": "Item not available in stock" }
```

**POST /store/chat/{id} body:**

```json
{ "message": "Can you clarify the quantity needed?" }
```

---

## Status Transition Rules

| From                     | Action         | To                   | Who              |
| ------------------------ | -------------- | -------------------- | ---------------- |
| `RAISED`                 | Admin reply    | `REPLIED`            | ADMIN            |
| `RAISED`                 | Admin assign   | `ASSIGNED`           | ADMIN            |
| `RAISED`                 | Admin reject   | `REJECTED`           | ADMIN            |
| `REPLIED`                | User reply     | `RAISED`             | USER/ADMIN/STAFF |
| `ASSIGNED`               | Staff start    | `IN_PROGRESS`        | STAFF            |
| `ASSIGNED`/`IN_PROGRESS` | Staff reassign | `REASSIGN_REQUESTED` | STAFF            |
| `REASSIGN_REQUESTED`     | Admin assign   | `ASSIGNED`           | ADMIN            |
| `IN_PROGRESS`            | Staff finish   | `COMPLETED`          | STAFF            |

## Store Request Status Transitions

| From       | Action        | To          | Who   |
| ---------- | ------------- | ----------- | ----- |
| `PENDING`  | Store approve | `APPROVED`  | STORE |
| `PENDING`  | Store reject  | `REJECTED`  | STORE |
| `APPROVED` | Store fulfil  | `FULFILLED` | STORE |
