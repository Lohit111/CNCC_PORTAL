# API Endpoints Documentation

Base URL: `http://localhost:8000`

All endpoints require Firebase Authentication token in the header:
```
Authorization: Bearer <firebase_token>
```

---

## 1. Users (`/api/v1/users`)

Manages user profiles and information.

### 1.1 Get Current User Profile
**GET** `/api/v1/users/me`

**Access:** USER, ADMIN, STAFF, STORE (all authenticated users)

**Response:**
```json
{
  "id": "firebase-uid",
  "email": "user@example.com",
  "role": "USER",
  "is_active": true,
  "created_at": "2024-01-01T00:00:00"
}
```

**Effects:**
- Returns current authenticated user's profile
- Includes user's assigned role
- No data modification
- Useful for displaying user info in UI
- Can be called on app startup to verify authentication

**Use Cases:**
- Display user profile in navigation bar
- Check user's role to show/hide UI elements
- Verify authentication status
- Get user ID for creating requests

---

### 1.2 Get All Users
**GET** `/api/v1/users/?skip=0&limit=100`

**Access:** ADMIN only

**Query Parameters:**
- `skip` (optional, default: 0)
- `limit` (optional, default: 100, max: 1000)

**Response:**
```json
{
  "items": [
    {
      "id": "firebase-uid",
      "email": "user@example.com",
      "is_active": true,
      "created_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 50
}
```

**Effects:**
- Reads all users from database
- Returns paginated list
- No data modification

---

### 1.3 Get User by ID
**GET** `/api/v1/users/{user_id}`

**Access:** ADMIN only

**Response:** Single user object

**Effects:**
- Reads single user from database
- Returns 404 if user not found
- No data modification

---

### 1.4 Update User
**PUT** `/api/v1/users/{user_id}`

**Access:** ADMIN only

**Request Body:**
```json
{
  "is_active": false
}
```

**Response:** Updated user object

**Effects:**
- Updates user fields in database
- Can activate/deactivate users
- Returns 404 if user not found

---

## 2. Requests (`/api/v1/requests`)

Manages ticket/request lifecycle from creation to resolution.

### 1.1 Create Request
**POST** `/api/v1/requests/`

**Access:** USER only

**Request Body:**
```json
{
  "main_type_id": 1,
  "sub_type_id": 2,
  "description": "Detailed description of the issue"
}
```

**Response:** Request object with auto-generated ID and status "RAISED"

**Effects:**
- Creates new request in database
- Auto-sets `raised_by` to current user's ID
- Auto-sets `status` to "RAISED"
- Auto-generates UUID for request ID
- Sets `created_at` and `updated_at` timestamps

**Validations:**
- `main_type_id` must exist in database
- `sub_type_id` must exist and belong to the specified main_type
- `description` is required

---

### 2.2 Get All Requests
**GET** `/api/v1/requests/?skip=0&limit=20`

**Access:** ADMIN, STAFF

**Query Parameters:**
- `skip` (optional, default: 0) - Number of records to skip for pagination
- `limit` (optional, default: 20, max: 100) - Number of records to return

**Response:**
```json
{
  "items": [/* array of request objects */],
  "total": 150,
  "page": 1,
  "page_size": 20,
  "total_pages": 8
}
```

**Effects:**
- Reads all requests from database with pagination
- No data modification

---

### 2.3 Get Request by ID
**GET** `/api/v1/requests/{request_id}`

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Single request object

**Effects:**
- Reads single request from database
- Returns 404 if request not found
- No data modification

---

### 2.4 Update Request
**PUT** `/api/v1/requests/{request_id}`

**Access:** ADMIN, STAFF

**Request Body:**
```json
{
  "status": "IN_PROGRESS",
  "description": "Updated description (optional)"
}
```

**Possible Status Values:**
- `RAISED` - Initial status when created
- `REJECTED` - Admin/Staff rejected the request
- `REPLIED` - Admin/Staff replied to user
- `ASSIGNED` - Request assigned to staff
- `IN_PROGRESS` - Staff working on it
- `REASSIGN_REQUESTED` - Staff requested reassignment
- `COMPLETED` - Request resolved

**Response:** Updated request object

**Effects:**
- Updates request fields in database
- Updates `updated_at` timestamp
- Can change status to progress request through workflow
- Returns 404 if request not found

---

### 2.5 Delete Request
**DELETE** `/api/v1/requests/{request_id}`

**Access:** ADMIN only

**Response:**
```json
{
  "detail": "Request deleted successfully"
}
```

**Effects:**
- **CASCADE DELETE** - Deletes request and ALL related data:
  - All comments on this request
  - All assignments for this request
  - All store requests linked to this request
- Permanent deletion, cannot be undone
- Returns 404 if request not found

---

### 2.6 Add Comment to Request
**POST** `/api/v1/requests/{request_id}/comments`

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Request Body:**
```json
{
  "message": "Comment text here",
  "type": "REPLY"
}
```

**Comment Types:**
- `REPLY` - Response to previous comment
- `REJECTION` - Rejection reason
- `NOTE` - Internal note
- `FORWARD_REASON` - Reason for forwarding

**Response:** Created comment object

**Effects:**
- Creates new comment in database
- Auto-sets `sender_id` to current user's ID
- Auto-sets `sender_role` to current user's role
- Auto-sets `created_at` timestamp
- Links comment to request via `request_id`
- Returns 404 if request not found

---

### 2.7 Get Request Comments
**GET** `/api/v1/requests/{request_id}/comments`

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Array of comment objects ordered by creation time

**Effects:**
- Reads all comments for a request
- Returns comments in chronological order (timeline view)
- Returns 404 if request not found
- No data modification

---

## 3. Roles (`/api/v1/roles`)

Manages user role assignments for access control.

### 3.1 Get All Roles
**GET** `/api/v1/roles/?skip=0&limit=100`

**Access:** ADMIN only

**Query Parameters:**
- `skip` (optional, default: 0)
- `limit` (optional, default: 100, max: 1000)

**Response:**
```json
{
  "items": [
    {
      "email": "user@example.com",
      "role": "USER",
      "created_at": "2024-01-01T00:00:00",
      "updated_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 50
}
```

**Effects:**
- Reads all role assignments
- No data modification

---

### 3.2 Get Role by Email
**GET** `/api/v1/roles/{email}`

**Access:** ADMIN only

**Response:** Single role object

**Effects:**
- Reads role for specific email
- Returns 404 if role not found
- No data modification

---

### 3.3 Create Role
**POST** `/api/v1/roles/`

**Access:** ADMIN only

**Request Body:**
```json
{
  "email": "newuser@example.com",
  "role": "USER"
}
```

**Valid Roles:**
- `USER` - Regular user, can create requests
- `ADMIN` - Full system access
- `STAFF` - Can manage assigned requests
- `STORE` - Can manage equipment requests

**Response:** Created role object

**Effects:**
- Creates new role assignment in database
- User with this email can now authenticate
- Returns 409 if role already exists for this email
- Sets `created_at` and `updated_at` timestamps

---

### 3.4 Update Role
**PUT** `/api/v1/roles/{email}`

**Access:** ADMIN only

**Request Body:**
```json
{
  "role": "STAFF"
}
```

**Response:** Updated role object

**Effects:**
- Updates role for existing email
- Changes user's access permissions immediately
- Updates `updated_at` timestamp
- Returns 404 if role not found

---

### 3.5 Delete Role
**DELETE** `/api/v1/roles/{email}`

**Access:** ADMIN only

**Response:**
```json
{
  "detail": "Role deleted successfully"
}
```

**Effects:**
- Removes role assignment from database
- User can no longer authenticate (will get 403 error)
- Does NOT delete user's data (requests, comments, etc.)
- Returns 404 if role not found

---

### 3.6 Bulk Create/Update Roles
**POST** `/api/v1/roles/bulk`

**Access:** ADMIN only

**Request Body:**
```json
{
  "roles": [
    {"email": "user1@example.com", "role": "USER"},
    {"email": "user2@example.com", "role": "STAFF"},
    {"email": "user3@example.com", "role": "ADMIN"}
  ]
}
```

**Response:**
```json
{
  "detail": "Successfully processed 3 roles",
  "created": 2,
  "updated": 1
}
```

**Effects:**
- Creates new roles for emails that don't exist
- Updates existing roles for emails that already exist
- Processes all roles in a single transaction
- Useful for CSV imports or batch operations

---

## 4. Types (`/api/v1/types`)

Manages request categorization (Main Types and Sub Types).

### 4.1 Get All Main Types
**GET** `/api/v1/types/main`

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Array of main type objects

**Effects:**
- Reads all main type categories
- Used for request creation dropdown
- No data modification

---

### 4.2 Get Main Type by ID
**GET** `/api/v1/types/main/{main_type_id}`

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Single main type object

**Effects:**
- Reads single main type
- Returns 404 if not found
- No data modification

---

### 4.3 Create Main Type
**POST** `/api/v1/types/main`

**Access:** ADMIN only

**Request Body:**
```json
{
  "name": "Hardware Issues"
}
```

**Response:** Created main type object with auto-generated ID

**Effects:**
- Creates new main type category
- Auto-sets `created_by` to current admin's ID
- Auto-sets `created_at` timestamp
- Returns 409 if main type with same name already exists

---

### 4.4 Update Main Type
**PUT** `/api/v1/types/main/{main_type_id}`

**Access:** ADMIN only

**Request Body:**
```json
{
  "name": "Updated Hardware Issues"
}
```

**Response:** Updated main type object

**Effects:**
- Updates main type name
- Returns 404 if not found

---

### 4.5 Delete Main Type
**DELETE** `/api/v1/types/main/{main_type_id}`

**Access:** ADMIN only

**Response:**
```json
{
  "detail": "Main type deleted successfully"
}
```

**Effects:**
- **CASCADE DELETE** - Deletes main type and ALL sub types under it
- Existing requests with this type will have broken references
- Returns 404 if not found

---

### 4.6 Get Sub Types for Main Type
**GET** `/api/v1/types/main/{main_type_id}/sub`

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Array of sub type objects for the specified main type

**Effects:**
- Reads all sub types belonging to a main type
- Used for cascading dropdown in request creation
- Returns 404 if main type not found
- No data modification

---

### 4.7 Get Sub Type by ID
**GET** `/api/v1/types/sub/{sub_type_id}`

**Access:** USER, ADMIN, STAFF, STORE (all roles)

**Response:** Single sub type object

**Effects:**
- Reads single sub type
- Returns 404 if not found
- No data modification

---

### 4.8 Create Sub Type
**POST** `/api/v1/types/sub`

**Access:** ADMIN only

**Request Body:**
```json
{
  "name": "Laptop Issues",
  "main_type_id": 1
}
```

**Response:** Created sub type object with auto-generated ID

**Effects:**
- Creates new sub type under specified main type
- Validates that main_type_id exists
- Returns 404 if main type not found

---

### 4.9 Update Sub Type
**PUT** `/api/v1/types/sub/{sub_type_id}`

**Access:** ADMIN only

**Request Body:**
```json
{
  "name": "Updated Laptop Issues"
}
```

**Response:** Updated sub type object

**Effects:**
- Updates sub type name
- Returns 404 if not found

---

### 4.10 Delete Sub Type
**DELETE** `/api/v1/types/sub/{sub_type_id}`

**Access:** ADMIN only

**Response:**
```json
{
  "detail": "Sub type deleted successfully"
}
```

**Effects:**
- Deletes sub type
- Existing requests with this sub type will have broken references
- Returns 404 if not found

---

## 5. Assignments (`/api/v1/assignments`)

Manages staff assignments to requests.

### 5.1 Get Assignments by Request
**GET** `/api/v1/assignments/request/{request_id}`

**Access:** ADMIN, STAFF

**Response:** Array of assignment objects for the request

**Effects:**
- Reads all assignments (active and inactive) for a request
- Shows assignment history
- No data modification

---

### 5.2 Get Assignments by Staff
**GET** `/api/v1/assignments/staff/{staff_id}?active_only=true`

**Access:** ADMIN, STAFF

**Query Parameters:**
- `active_only` (optional, default: true) - Filter for active assignments only

**Response:** Array of assignment objects for the staff member

**Effects:**
- Reads all assignments for a staff member
- Can filter for only active assignments
- Used to show staff workload
- No data modification

---

### 5.3 Get Assignment by ID
**GET** `/api/v1/assignments/{assignment_id}`

**Access:** ADMIN, STAFF

**Response:** Single assignment object

**Effects:**
- Reads single assignment
- Returns 404 if not found
- No data modification

---

### 5.4 Create Assignment
**POST** `/api/v1/assignments/`

**Access:** ADMIN only

**Request Body:**
```json
{
  "request_id": "uuid-here",
  "staff_id": "firebase-uid-here"
}
```

**Response:** Created assignment object

**Effects:**
- Creates new assignment linking staff to request
- Auto-sets `assigned_by` to current admin's ID
- Auto-sets `is_active` to true
- Auto-sets `created_at` timestamp
- **DEACTIVATES all previous assignments for this request** (sets is_active=false)
- Only one active assignment per request at a time
- Validates that request exists
- Validates that staff user exists
- Returns 404 if request or staff not found

---

### 5.5 Update Assignment
**PUT** `/api/v1/assignments/{assignment_id}`

**Access:** ADMIN only

**Request Body:**
```json
{
  "is_active": false
}
```

**Response:** Updated assignment object

**Effects:**
- Updates assignment fields
- Can deactivate assignment by setting is_active=false
- Returns 404 if not found

---

### 5.6 Delete Assignment
**DELETE** `/api/v1/assignments/{assignment_id}`

**Access:** ADMIN only

**Response:**
```json
{
  "detail": "Assignment deleted successfully"
}
```

**Effects:**
- Permanently deletes assignment record
- Does NOT check if this leaves request unassigned
- Returns 404 if not found

---

## 6. Store Requests (`/api/v1/store-requests`)

Manages equipment/supply requests from staff to store personnel.

### 6.1 Get All Store Requests
**GET** `/api/v1/store-requests/?skip=0&limit=20`

**Access:** STORE, ADMIN

**Query Parameters:**
- `skip` (optional, default: 0)
- `limit` (optional, default: 20, max: 100)

**Response:**
```json
{
  "items": [/* array of store request objects */],
  "total": 50
}
```

**Effects:**
- Reads all store requests with pagination
- No data modification

---

### 6.2 Get Store Requests by Status
**GET** `/api/v1/store-requests/status/{status}?skip=0&limit=20`

**Access:** STORE, ADMIN

**Path Parameters:**
- `status` - One of: PENDING, APPROVED, REJECTED, FULFILLED

**Query Parameters:**
- `skip` (optional, default: 0)
- `limit` (optional, default: 20, max: 100)

**Response:**
```json
{
  "items": [/* filtered store request objects */],
  "total": 15
}
```

**Effects:**
- Reads store requests filtered by status
- Useful for store dashboard views
- No data modification

---

### 6.3 Get Store Requests by Parent Request
**GET** `/api/v1/store-requests/parent/{parent_request_id}`

**Access:** STAFF, STORE, ADMIN

**Response:** Array of store request objects linked to the parent request

**Effects:**
- Reads all store requests created for a specific parent request
- Shows equipment needs for a ticket
- No data modification

---

### 6.4 Get Store Request by ID
**GET** `/api/v1/store-requests/{store_request_id}`

**Access:** STAFF, STORE, ADMIN

**Response:** Single store request object

**Effects:**
- Reads single store request
- Returns 404 if not found
- No data modification

---

### 6.5 Create Store Request
**POST** `/api/v1/store-requests/`

**Access:** STAFF only

**Request Body:**
```json
{
  "parent_request_id": "uuid-of-main-request",
  "description": "Need 2x HDMI cables and 1x USB hub"
}
```

**Response:** Created store request object

**Effects:**
- Creates new store request
- Auto-sets `requested_by` to current staff's ID
- Auto-sets `status` to "PENDING"
- Auto-generates UUID for store request ID
- Auto-sets `created_at` and `updated_at` timestamps
- Links to parent request
- Validates that parent request exists
- Returns 404 if parent request not found

---

### 6.6 Update Store Request
**PUT** `/api/v1/store-requests/{store_request_id}`

**Access:** STORE, ADMIN

**Request Body:**
```json
{
  "status": "APPROVED",
  "response_comment": "Items available, will be delivered"
}
```

**Response:** Updated store request object

**Effects:**
- Updates store request fields
- Can change status and add comments
- Updates `updated_at` timestamp
- Returns 404 if not found

---

### 6.7 Respond to Store Request
**POST** `/api/v1/store-requests/{store_request_id}/respond`

**Access:** STORE only

**Request Body:**
```json
{
  "status": "APPROVED",
  "response_comment": "Items ready for pickup"
}
```

**Valid Status Values:**
- `APPROVED` - Store approved the request
- `REJECTED` - Store rejected the request
- `FULFILLED` - Items delivered/completed

**Response:** Updated store request object

**Effects:**
- Updates store request status
- Auto-sets `responded_by` to current store user's ID
- Sets `response_comment` if provided
- Updates `updated_at` timestamp
- Returns 400 if invalid status
- Returns 404 if store request not found

---

### 6.8 Delete Store Request
**DELETE** `/api/v1/store-requests/{store_request_id}`

**Access:** ADMIN only

**Response:**
```json
{
  "detail": "Store request deleted successfully"
}
```

**Effects:**
- Permanently deletes store request
- Does NOT affect parent request
- Returns 404 if not found

---

## Error Responses

All endpoints may return these error codes:

### 400 Bad Request
```json
{
  "detail": "Validation error message"
}
```
- Invalid data format
- Business logic validation failed

### 401 Unauthorized
```json
{
  "detail": "Invalid Firebase token"
}
```
- Missing or invalid authentication token

### 403 Forbidden
```json
{
  "detail": "Access denied: Required role(s): ['ADMIN']"
}
```
- User doesn't have required role
- No role assigned to email

### 404 Not Found
```json
{
  "detail": "Resource not found"
}
```
- Requested resource doesn't exist

### 409 Conflict
```json
{
  "detail": "Resource already exists"
}
```
- Duplicate creation attempt

### 500 Internal Server Error
```json
{
  "detail": "Database error: ..."
}
```
- Server-side error
- Database connection issues

---

## Data Models

### Request Object
```json
{
  "id": "uuid-string",
  "raised_by": "firebase-uid",
  "main_type_id": 1,
  "sub_type_id": 2,
  "description": "Issue description",
  "status": "RAISED",
  "created_at": "2024-01-01T00:00:00",
  "updated_at": "2024-01-01T00:00:00"
}
```

### Comment Object
```json
{
  "id": 123,
  "request_id": "uuid-string",
  "sender_id": "firebase-uid",
  "sender_role": "ADMIN",
  "message": "Comment text",
  "type": "REPLY",
  "created_at": "2024-01-01T00:00:00"
}
```

### Assignment Object
```json
{
  "id": 123,
  "request_id": "uuid-string",
  "staff_id": "firebase-uid",
  "assigned_by": "firebase-uid",
  "is_active": true,
  "created_at": "2024-01-01T00:00:00"
}
```

### Store Request Object
```json
{
  "id": "uuid-string",
  "parent_request_id": "uuid-string",
  "requested_by": "firebase-uid",
  "description": "Equipment needed",
  "status": "PENDING",
  "responded_by": "firebase-uid",
  "response_comment": "Response text",
  "created_at": "2024-01-01T00:00:00",
  "updated_at": "2024-01-01T00:00:00"
}
```

### Role Object
```json
{
  "email": "user@example.com",
  "role": "USER",
  "created_at": "2024-01-01T00:00:00",
  "updated_at": "2024-01-01T00:00:00"
}
```

### Main Type Object
```json
{
  "id": 1,
  "name": "Hardware Issues",
  "created_by": "firebase-uid",
  "created_at": "2024-01-01T00:00:00"
}
```

### Sub Type Object
```json
{
  "id": 1,
  "name": "Laptop Issues",
  "main_type_id": 1
}
```
