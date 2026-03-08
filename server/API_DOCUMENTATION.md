# API Documentation

Complete API reference for the Request Management System with track-based timeline.

**Base URL:** http://localhost:8000

**Authentication:** All endpoints require Firebase Authentication token in header:
Authorization: Bearer <firebase_token>

---

## Table of Contents
1. Users API
2. Roles API  
3. Requests API
4. Request Types API
5. Assignments API
6. Store Requests API
7. Data Models
8. Error Responses

---

## Users API

### GET /api/v1/users/me
Get current authenticated user profile.

**Access:** All authenticated users

**Response:** User object with id, email, role, is_active, created_at

**Database Effects:** None (read-only)

---

### GET /api/v1/users/requests
Get current user requests with pagination.

**Access:** All authenticated users

**Query Parameters:** skip (default: 0), limit (default: 20, max: 100)

**Response:** Paginated list of request objects

**Database Effects:** None (read-only)

---

### GET /api/v1/users/
Get all users (paginated).

**Access:** ADMIN only

**Query Parameters:** skip (default: 0), limit (default: 100, max: 1000)

**Response:** Paginated list of user objects

**Database Effects:** None (read-only)

---

### GET /api/v1/users/{user_id}
Get user by ID.

**Access:** ADMIN only

**Response:** Single user object

**Database Effects:** None (read-only)

---

### PUT /api/v1/users/{user_id}
Update user.

**Access:** ADMIN only

**Request Body:** is_active field

**Response:** Updated user object

**Database Effects:** Updates users table, can activate/deactivate users

---

## Roles API

### GET /api/v1/roles/
Get all role assignments.

**Access:** ADMIN only

**Query Parameters:** skip (default: 0), limit (default: 100, max: 1000)

**Response:** Paginated list of role objects

**Database Effects:** None (read-only)

---

### GET /api/v1/roles/{email}
Get role by email.

**Access:** ADMIN only

**Response:** Single role object

**Database Effects:** None (read-only)

---

### POST /api/v1/roles/
Create a new role assignment.

**Access:** ADMIN only

**Request Body:** email, role (USER/ADMIN/STAFF/STORE)

**Response:** Created role object

**Database Effects:** Inserts into roles table, sets timestamps, user can now authenticate

**Errors:** 409 if role already exists for email

---

### PUT /api/v1/roles/{email}
Update role assignment.

**Access:** ADMIN only

**Request Body:** role field

**Response:** Updated role object

**Database Effects:** Updates roles table, updates timestamp, changes permissions immediately

---

### DELETE /api/v1/roles/{email}
Delete role assignment.

**Access:** ADMIN only

**Response:** Success message

**Database Effects:** Deletes from roles table, user can no longer authenticate, does NOT delete user data

---

### POST /api/v1/roles/bulk
Bulk create or update roles.

**Access:** ADMIN only

**Request Body:** Array of role objects

**Response:** Summary of created and updated roles

**Database Effects:** Creates new roles or updates existing ones in single transaction

---

## Requests API

### POST /api/v1/requests/
Create a new request.

**Access:** USER only

**Request Body:** main_type_id, sub_type_id, description

**Response:** Created request object with auto-generated ID

**Database Effects:**
1. Inserts into requests table (UUID, raised_by, status=RAISED, is_active=true, timestamps)
2. Inserts into request_tracks table (action_type=RAISED, performed_by, performed_by_role=USER, metadata)

**Validations:** main_type_id and sub_type_id must exist and be related

---

### GET /api/v1/requests/
Get all requests (paginated).

**Access:** ADMIN, STAFF

**Query Parameters:** skip (default: 0), limit (default: 20, max: 100)

**Response:** Paginated list of request objects

**Database Effects:** None (read-only)

---

### GET /api/v1/requests/{request_id}
Get request by ID.

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Single request object

**Database Effects:** None (read-only)

---

### PUT /api/v1/requests/{request_id}
Update request.

**Access:** ADMIN, STAFF

**Request Body:** status, description (optional)

**Valid Status Values:** RAISED, REPLIED, REJECTED, ASSIGNED, IN_PROGRESS, REASSIGN_REQUESTED, COMPLETED

**Response:** Updated request object

**Database Effects:** Updates requests table, updates timestamp

**Note:** Does NOT automatically create tracks. Use POST /comments endpoint separately.

---

### DELETE /api/v1/requests/{request_id}
Delete request and all related data.

**Access:** ADMIN only

**Response:** Success message

**Database Effects (CASCADE DELETE):**
1. Deletes from request_tracks where request_id matches
2. Deletes from assignments where request_id matches
3. Deletes from store_requests where parent_request_id matches (also deletes store_chats and related tracks)
4. Deletes from requests table

**Warning:** Permanent deletion, cannot be undone

---

### POST /api/v1/requests/{request_id}/comments
Add a track entry to request timeline.

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Request Body:** action_type, comment (optional), metadata (optional)

**Common Action Types:** RAISED, REPLIED, REJECTED, ASSIGNED, REASSIGN_REQUESTED, IN_PROGRESS, COMPLETED

**Response:** Created track object

**Database Effects:** Inserts into request_tracks table with sender_id, sender_role, timestamp

**Note:** Creates track entry. Status changes done via PUT /requests/{request_id}

---

### GET /api/v1/requests/{request_id}/comments
Get all tracks for a request (timeline view).

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Array of track objects ordered by created_at ASC (chronological)

**Database Effects:** None (read-only)

---

## Request Types API

### GET /api/v1/types/main
Get all main types.

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Array of main type objects

**Database Effects:** None (read-only)

---

### GET /api/v1/types/main/{main_type_id}
Get main type by ID.

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Single main type object

**Database Effects:** None (read-only)

---

### POST /api/v1/types/main
Create a new main type.

**Access:** ADMIN only

**Request Body:** name

**Response:** Created main type object with auto-generated ID

**Database Effects:** Inserts into main_types table, sets created_by and timestamp

**Errors:** 409 if main type with same name already exists

---

### PUT /api/v1/types/main/{main_type_id}
Update main type.

**Access:** ADMIN only

**Request Body:** name

**Response:** Updated main type object

**Database Effects:** Updates main_types table

---

### DELETE /api/v1/types/main/{main_type_id}
Delete main type.

**Access:** ADMIN only

**Response:** Success message

**Database Effects (CASCADE):** Deletes from main_types table, deletes all sub_types where main_type_id matches

---

### GET /api/v1/types/main/{main_type_id}/sub
Get all sub types for a main type.

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Array of sub type objects

**Database Effects:** None (read-only)

---

### GET /api/v1/types/sub/{sub_type_id}
Get sub type by ID.

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Single sub type object

**Database Effects:** None (read-only)

---

### POST /api/v1/types/sub
Create a new sub type.

**Access:** ADMIN only

**Request Body:** name, main_type_id

**Response:** Created sub type object with auto-generated ID

**Database Effects:** Inserts into sub_types table, validates main_type_id exists

**Errors:** 404 if main type not found

---

### PUT /api/v1/types/sub/{sub_type_id}
Update sub type.

**Access:** ADMIN only

**Request Body:** name

**Response:** Updated sub type object

**Database Effects:** Updates sub_types table

---

### DELETE /api/v1/types/sub/{sub_type_id}
Delete sub type.

**Access:** ADMIN only

**Response:** Success message

**Database Effects:** Deletes from sub_types table

---

## Assignments API

### GET /api/v1/assignments/request/{request_id}
Get all assignments for a request.

**Access:** ADMIN, STAFF

**Response:** Array of assignment objects (includes inactive assignments)

**Database Effects:** None (read-only)

---

### GET /api/v1/assignments/staff/{staff_id}
Get all assignments for a staff member.

**Access:** ADMIN, STAFF

**Query Parameters:** active_only (default: true)

**Response:** Array of assignment objects

**Database Effects:** None (read-only)

---

### GET /api/v1/assignments/{assignment_id}
Get assignment by ID.

**Access:** ADMIN, STAFF

**Response:** Single assignment object

**Database Effects:** None (read-only)

---

### POST /api/v1/assignments/
Create a new assignment.

**Access:** ADMIN only

**Request Body:** request_id, staff_id

**Response:** Created assignment object

**Database Effects:**
1. Deactivates all previous assignments for this request (sets is_active=false)
2. Inserts into assignments table (assigned_by, is_active=true, timestamp)

**Note:** Only one active assignment per request at a time

**Validations:** Request and staff user must exist

**Errors:** 404 if request or staff not found

---

### PUT /api/v1/assignments/{assignment_id}
Update assignment.

**Access:** ADMIN only

**Request Body:** is_active field

**Response:** Updated assignment object

**Database Effects:** Updates assignments table

---

### DELETE /api/v1/assignments/{assignment_id}
Delete assignment.

**Access:** ADMIN only

**Response:** Success message

**Database Effects:** Deletes from assignments table (permanent)

---

## Store Requests API

### POST /api/v1/store-requests/
Create a new store request.

**Access:** STAFF only

**Request Body:** parent_request_id, description

**Response:** Created store request object

**Database Effects:**
1. Inserts into store_requests table (UUID, requested_by, status=PENDING, timestamps)
2. Inserts into request_tracks table (action_type=STORE_REQUEST_CREATED, comment=description, metadata)

**Validations:** Parent request must exist

**Errors:** 404 if parent request not found

---

### GET /api/v1/store-requests/
Get all store requests (paginated).

**Access:** STORE, ADMIN

**Query Parameters:** skip (default: 0), limit (default: 20, max: 100)

**Response:** Paginated list of store request objects

**Database Effects:** None (read-only)

---

### GET /api/v1/store-requests/status/{status}
Get store requests by status (paginated).

**Access:** STORE, ADMIN

**Path Parameters:** status (PENDING/APPROVED/REJECTED/FULFILLED)

**Query Parameters:** skip (default: 0), limit (default: 20, max: 100)

**Response:** Paginated filtered list of store request objects

**Database Effects:** None (read-only)

---

### GET /api/v1/store-requests/parent/{parent_request_id}
Get all store requests for a parent request.

**Access:** STAFF, STORE, ADMIN

**Response:** Array of store request objects

**Database Effects:** None (read-only)

---

### GET /api/v1/store-requests/{store_request_id}
Get store request by ID.

**Access:** STAFF, STORE, ADMIN

**Response:** Single store request object

**Database Effects:** None (read-only)

---

### PUT /api/v1/store-requests/{store_request_id}
Update store request.

**Access:** STORE, ADMIN

**Request Body:** status, response_comment

**Response:** Updated store request object

**Database Effects:** Updates store_requests table, updates timestamp

**Note:** For status changes with track creation, use POST /respond endpoint instead

---

### POST /api/v1/store-requests/{store_request_id}/respond
Respond to a store request (approve/reject/fulfill).

**Access:** STORE only

**Request Body:** status (APPROVED/REJECTED/FULFILLED), response_comment (optional)

**Response:** Updated store request object

**Database Effects:**
1. Updates store_requests table (status, responded_by, response_comment, timestamp)
2. Inserts into request_tracks table (action_type=STORE_REQUEST_APPROVED/REJECTED/FULFILLED, comment, metadata)

**Errors:** 400 if invalid status, 404 if store request not found

---

### DELETE /api/v1/store-requests/{store_request_id}
Delete store request.

**Access:** ADMIN only

**Response:** Success message

**Database Effects (CASCADE):** Deletes from store_chats, request_tracks, and store_requests tables

---

### POST /api/v1/store-requests/{store_request_id}/chat
Add a chat message to an APPROVED store request.

**Access:** STAFF, STORE

**Request Body:** message

**Response:** Created chat message object

**Database Effects:** Inserts into store_chats table (sender_id, sender_role, timestamp)

**Validations:** Store request must exist and status must be APPROVED

**Errors:** 404 if not found, 400 if status is not APPROVED

---

### GET /api/v1/store-requests/{store_request_id}/chat
Get all chat messages for a store request.

**Access:** STAFF, STORE, ADMIN

**Response:** Array of chat message objects ordered by created_at ASC (chronological)

**Database Effects:** None (read-only)

---

## Data Models

### User Object
- id (firebase-uid)
- email
- is_active (boolean)
- created_at (timestamp)

### Role Object
- email
- role (USER/ADMIN/STAFF/STORE)
- created_at (timestamp)
- updated_at (timestamp)

### Request Object
- id (uuid)
- raised_by (user id)
- main_type_id (integer)
- sub_type_id (integer)
- description (text)
- status (string)
- is_active (string: "true"/"false")
- created_at (timestamp)
- updated_at (timestamp)

### Track Object
- id (integer)
- request_id (uuid, nullable)
- store_request_id (uuid, nullable)
- action_type (string)
- performed_by (user id)
- performed_by_role (string)
- comment (text, nullable)
- metadata (JSON, nullable)
- created_at (timestamp)

### Assignment Object
- id (integer)
- request_id (uuid)
- staff_id (user id)
- assigned_by (user id)
- is_active (boolean)
- created_at (timestamp)

### Store Request Object
- id (uuid)
- parent_request_id (uuid)
- requested_by (user id)
- description (text)
- status (string)
- responded_by (user id, nullable)
- response_comment (text, nullable)
- created_at (timestamp)
- updated_at (timestamp)

### Store Chat Object
- id (integer)
- store_request_id (uuid)
- sender_id (user id)
- sender_role (string)
- message (text)
- created_at (timestamp)

### Main Type Object
- id (integer)
- name (string)
- created_by (user id)
- created_at (timestamp)

### Sub Type Object
- id (integer)
- name (string)
- main_type_id (integer)

---

## Error Responses

### 400 Bad Request
Invalid data format, business logic validation failed, invalid status value

### 401 Unauthorized
Missing or invalid authentication token

### 403 Forbidden
User doesn't have required role, no role assigned to email

### 404 Not Found
Requested resource doesn't exist

### 409 Conflict
Duplicate creation attempt

### 500 Internal Server Error
Server-side error, database connection issues

---

## Database Schema Summary

### Tables
1. users - User profiles
2. roles - Role assignments (email to role mapping)
3. requests - Main requests/tickets
4. request_tracks - Timeline entries for requests and store requests
5. assignments - Staff assignments to requests
6. store_requests - Equipment/supply requests
7. store_chats - Chat messages for APPROVED store requests
8. main_types - Main request categories
9. sub_types - Sub-categories under main types

### Key Relationships
- requests.raised_by -> users.id
- requests.main_type_id -> main_types.id
- requests.sub_type_id -> sub_types.id
- request_tracks.request_id -> requests.id (nullable)
- request_tracks.store_request_id -> store_requests.id (nullable)
- request_tracks.performed_by -> users.id
- assignments.request_id -> requests.id
- assignments.staff_id -> users.id
- assignments.assigned_by -> users.id
- store_requests.parent_request_id -> requests.id
- store_requests.requested_by -> users.id
- store_requests.responded_by -> users.id (nullable)
- store_chats.store_request_id -> store_requests.id
- store_chats.sender_id -> users.id
- sub_types.main_type_id -> main_types.id

### Cascade Deletes
- Delete request -> deletes tracks, assignments, store requests (and their chats/tracks)
- Delete main type -> deletes all sub types
- Delete store request -> deletes chats and tracks

---

## Notes

- All timestamps are in UTC
- UUIDs are auto-generated for requests and store requests
- Integer IDs are auto-incremented for tracks, assignments, chats, and types
- Tracks are ordered chronologically (created_at ASC) for timeline view
- Only one active assignment per request at a time
- Store chat only available for APPROVED store requests
- Multiple staff can be assigned to same request (atomic operations)
- is_active field on requests allows marking old requests as inactive
