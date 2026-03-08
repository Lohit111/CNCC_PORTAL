# User Flow Documentation

This document describes the complete workflow for each user role in the system, including accessible endpoints, permissions, and typical usage patterns.

---

## Table of Contents
1. [USER Role Flow](#user-role-flow)
2. [ADMIN Role Flow](#admin-role-flow)
3. [STAFF Role Flow](#staff-role-flow)
4. [STORE Role Flow](#store-role-flow)

---

## USER Role Flow

### Overview
Regular users who create and track requests for issues or support needs.

### Accessible Endpoints

#### Profile & Authentication
- `GET /api/v1/users/me` - View own profile
- `GET /api/v1/users/requests` - View own requests (paginated)

#### Request Management
- `POST /api/v1/requests/` - Create new request
- `GET /api/v1/requests/{request_id}` - View request details
- `POST /api/v1/requests/{request_id}/comments` - Add track entry (reply/update)
- `GET /api/v1/requests/{request_id}/comments` - View request timeline/tracks

#### Request Types (Read-Only)
- `GET /api/v1/types/main` - View all main types
- `GET /api/v1/types/main/{main_type_id}` - View main type details
- `GET /api/v1/types/main/{main_type_id}/sub` - View sub types for main type
- `GET /api/v1/types/sub/{sub_type_id}` - View sub type details

### Typical Workflow

#### 1. Creating a Request
```
1. User logs in → GET /api/v1/users/me (verify authentication)
2. View available types → GET /api/v1/types/main
3. Select main type → GET /api/v1/types/main/{id}/sub
4. Create request → POST /api/v1/requests/
   Body: {
     "main_type_id": 1,
     "sub_type_id": 2,
     "description": "Issue description"
   }
   
   Effect: 
   - Request created with status "RAISED"
   - is_active = "true"
   - Track created: action_type="RAISED"
```

#### 2. Tracking Request Status
```
1. View own requests → GET /api/v1/users/requests
2. View specific request → GET /api/v1/requests/{request_id}
3. View timeline → GET /api/v1/requests/{request_id}/comments
   
   Timeline shows:
   - RAISED (initial creation)
   - REPLIED (admin/staff responses)
   - REJECTED (if rejected)
   - ASSIGNED (when assigned to staff)
   - IN_PROGRESS (staff working)
   - COMPLETED (resolved)
```

#### 3. Responding to REPLIED Status
When admin replies (status = REPLIED), user has 2 options:

**Option A: Update Existing Request (Continue Track)**
```
POST /api/v1/requests/{request_id}/comments
Body: {
  "action_type": "USER_UPDATED",
  "performed_by": "{user_id}",
  "performed_by_role": "USER",
  "comment": "Updated information..."
}

Then update request:
PUT /api/v1/requests/{request_id}
Body: {
  "description": "Updated description",
  "status": "RAISED"
}

Effect:
- Same request_id, continues same track
- Status back to RAISED
- Track entry added: "User updated request"
```

**Option B: Create New Request (Fresh Start)**
```
POST /api/v1/requests/
Body: {
  "main_type_id": 1,
  "sub_type_id": 2,
  "description": "New request description"
}

Then mark old request inactive:
PUT /api/v1/requests/{old_request_id}
Body: {
  "is_active": "false"
}

Effect:
- New request with new request_id
- New track timeline
- Old request marked inactive
```

### What USER Can View
- ✅ Own profile and requests
- ✅ Request details for their requests
- ✅ Complete timeline/tracks for their requests
- ✅ All request types (for creating requests)
- ❌ Other users' requests
- ❌ Staff assignments
- ❌ Store requests
- ❌ Admin functions

### Permissions Summary
| Action | Allowed |
|--------|---------|
| Create Request | ✅ |
| View Own Requests | ✅ |
| Update Own Request | ✅ (via track/comment) |
| Delete Request | ❌ |
| View All Requests | ❌ |
| Assign Staff | ❌ |
| Manage Roles | ❌ |
| Manage Types | ❌ |

---

## ADMIN Role Flow

### Overview
System administrators with full access to manage users, requests, assignments, and system configuration.

### Accessible Endpoints

#### All USER Endpoints Plus:

#### User Management
- `GET /api/v1/users/` - View all users (paginated)
- `GET /api/v1/users/{user_id}` - View user details
- `PUT /api/v1/users/{user_id}` - Update user

#### Role Management
- `GET /api/v1/roles/` - View all roles
- `GET /api/v1/roles/{email}` - View role by email
- `POST /api/v1/roles/` - Create role
- `PUT /api/v1/roles/{email}` - Update role
- `DELETE /api/v1/roles/{email}` - Delete role
- `POST /api/v1/roles/bulk` - Bulk create/update roles

#### Request Management (Full Access)
- `GET /api/v1/requests/` - View all requests (paginated)
- `PUT /api/v1/requests/{request_id}` - Update request status
- `DELETE /api/v1/requests/{request_id}` - Delete request (cascade)

#### Assignment Management
- `GET /api/v1/assignments/request/{request_id}` - View assignments for request
- `GET /api/v1/assignments/staff/{staff_id}` - View staff assignments
- `GET /api/v1/assignments/{assignment_id}` - View assignment details
- `POST /api/v1/assignments/` - Create assignment
- `PUT /api/v1/assignments/{assignment_id}` - Update assignment
- `DELETE /api/v1/assignments/{assignment_id}` - Delete assignment

#### Type Management
- `POST /api/v1/types/main` - Create main type
- `PUT /api/v1/types/main/{main_type_id}` - Update main type
- `DELETE /api/v1/types/main/{main_type_id}` - Delete main type (cascade)
- `POST /api/v1/types/sub` - Create sub type
- `PUT /api/v1/types/sub/{sub_type_id}` - Update sub type
- `DELETE /api/v1/types/sub/{sub_type_id}` - Delete sub type

#### Store Request Management
- `GET /api/v1/store-requests/` - View all store requests
- `GET /api/v1/store-requests/status/{status}` - Filter by status
- `GET /api/v1/store-requests/parent/{parent_request_id}` - View by parent
- `GET /api/v1/store-requests/{store_request_id}` - View details
- `PUT /api/v1/store-requests/{store_request_id}` - Update store request
- `DELETE /api/v1/store-requests/{store_request_id}` - Delete store request
- `GET /api/v1/store-requests/{store_request_id}/chat` - View chat messages

### Typical Workflows

#### 1. Managing Incoming Requests
```
1. View all requests → GET /api/v1/requests/
2. View specific request → GET /api/v1/requests/{request_id}
3. View timeline → GET /api/v1/requests/{request_id}/comments

Admin has 3 options:

Option A: REJECT
-----------------
POST /api/v1/requests/{request_id}/comments
Body: {
  "action_type": "REJECTED",
  "performed_by": "{admin_id}",
  "performed_by_role": "ADMIN",
  "comment": "Rejection reason..."
}

PUT /api/v1/requests/{request_id}
Body: { "status": "REJECTED" }

Effect:
- Status = REJECTED
- Track created with rejection reason
- Request closed

Option B: REPLY
-----------------
POST /api/v1/requests/{request_id}/comments
Body: {
  "action_type": "REPLIED",
  "performed_by": "{admin_id}",
  "performed_by_role": "ADMIN",
  "comment": "Need more information..."
}

PUT /api/v1/requests/{request_id}
Body: { "status": "REPLIED" }

Effect:
- Status = REPLIED
- Track created with admin's message
- User can now update or create new request

Option C: ASSIGN
-----------------
POST /api/v1/assignments/
Body: {
  "request_id": "{request_id}",
  "staff_id": "{staff_id}"
}

PUT /api/v1/requests/{request_id}
Body: { "status": "ASSIGNED" }

POST /api/v1/requests/{request_id}/comments
Body: {
  "action_type": "ASSIGNED",
  "performed_by": "{admin_id}",
  "performed_by_role": "ADMIN",
  "metadata": {
    "assigned_staff_ids": ["{staff_id}"]
  }
}

Effect:
- Status = ASSIGNED
- Assignment created (previous assignments deactivated)
- Track created with staff info
- Staff can now work on request
```

#### 2. Managing User Roles
```
1. View all roles → GET /api/v1/roles/
2. Create new role → POST /api/v1/roles/
   Body: {
     "email": "user@example.com",
     "role": "STAFF"
   }
3. Update role → PUT /api/v1/roles/{email}
4. Delete role → DELETE /api/v1/roles/{email}

Bulk operations:
POST /api/v1/roles/bulk
Body: {
  "roles": [
    {"email": "user1@example.com", "role": "USER"},
    {"email": "user2@example.com", "role": "STAFF"}
  ]
}
```

#### 3. Managing Request Types
```
1. Create main type → POST /api/v1/types/main
   Body: { "name": "Hardware Issues" }

2. Create sub types → POST /api/v1/types/sub
   Body: {
     "name": "Laptop Issues",
     "main_type_id": 1
   }

3. Update/Delete as needed
```

### What ADMIN Can View
- ✅ Everything in the system
- ✅ All users and their details
- ✅ All requests (any user)
- ✅ All assignments
- ✅ All store requests
- ✅ All roles
- ✅ Complete system analytics

### Permissions Summary
| Action | Allowed |
|--------|---------|
| Everything USER can do | ✅ |
| View All Requests | ✅ |
| Update Any Request | ✅ |
| Delete Requests | ✅ |
| Manage Roles | ✅ |
| Manage Types | ✅ |
| Create Assignments | ✅ |
| Manage Assignments | ✅ |
| View Store Requests | ✅ |
| Delete Store Requests | ✅ |

---

## STAFF Role Flow

### Overview
Technical staff who handle assigned requests and can request equipment from store.

### Accessible Endpoints

#### Profile & Requests
- `GET /api/v1/users/me` - View own profile
- `GET /api/v1/requests/` - View all requests (paginated)
- `GET /api/v1/requests/{request_id}` - View request details
- `PUT /api/v1/requests/{request_id}` - Update request status
- `POST /api/v1/requests/{request_id}/comments` - Add track entry
- `GET /api/v1/requests/{request_id}/comments` - View timeline

#### Assignment Management
- `GET /api/v1/assignments/request/{request_id}` - View request assignments
- `GET /api/v1/assignments/staff/{staff_id}` - View own assignments
- `GET /api/v1/assignments/{assignment_id}` - View assignment details

#### Store Request Management
- `GET /api/v1/store-requests/parent/{parent_request_id}` - View store requests for parent
- `GET /api/v1/store-requests/{store_request_id}` - View store request details
- `POST /api/v1/store-requests/` - Create store request
- `POST /api/v1/store-requests/{store_request_id}/chat` - Send chat message (APPROVED only)
- `GET /api/v1/store-requests/{store_request_id}/chat` - View chat messages

#### Request Types (Read-Only)
- `GET /api/v1/types/main` - View all main types
- `GET /api/v1/types/main/{main_type_id}/sub` - View sub types

### Typical Workflows

#### 1. Viewing Assigned Requests
```
1. View own assignments → GET /api/v1/assignments/staff/{staff_id}?active_only=true
2. View request details → GET /api/v1/requests/{request_id}
3. View timeline → GET /api/v1/requests/{request_id}/comments
```

#### 2. Working on Assigned Request
Staff has 2 options when assigned:

**Option A: Start Work**
```
POST /api/v1/requests/{request_id}/comments
Body: {
  "action_type": "IN_PROGRESS",
  "performed_by": "{staff_id}",
  "performed_by_role": "STAFF",
  "comment": "Started working on this..."
}

PUT /api/v1/requests/{request_id}
Body: { "status": "IN_PROGRESS" }

Effect:
- Status = IN_PROGRESS
- Track created
- All assigned staff see this status
```

**Option B: Request Reassignment**
```
POST /api/v1/requests/{request_id}/comments
Body: {
  "action_type": "REASSIGN_REQUESTED",
  "performed_by": "{staff_id}",
  "performed_by_role": "STAFF",
  "comment": "Cannot handle because..."
}

PUT /api/v1/requests/{request_id}
Body: { "status": "REASSIGN_REQUESTED" }

Effect:
- Status = REASSIGN_REQUESTED
- Track created with reason
- Goes back to admin for reassignment
- All assigned staff see this status
```

#### 3. Creating Store Request (Equipment Needed)
```
When IN_PROGRESS and equipment needed:

POST /api/v1/store-requests/
Body: {
  "parent_request_id": "{request_id}",
  "description": "Need 2x HDMI cables, 1x USB hub"
}

Effect:
- Store request created with status "PENDING"
- Track created on parent request: action_type="STORE_REQUEST_CREATED"
- Store personnel notified
```

#### 4. Communicating with Store (APPROVED Store Requests)
```
After store approves:

1. View chat → GET /api/v1/store-requests/{store_request_id}/chat

2. Send message → POST /api/v1/store-requests/{store_request_id}/chat
   Body: {
     "message": "When can I pick up the items?"
   }

3. Store responds in chat

4. When items delivered, store marks as FULFILLED
```

#### 5. Completing Request
```
POST /api/v1/requests/{request_id}/comments
Body: {
  "action_type": "COMPLETED",
  "performed_by": "{staff_id}",
  "performed_by_role": "STAFF",
  "comment": "Issue resolved..."
}

PUT /api/v1/requests/{request_id}
Body: { "status": "COMPLETED" }

Effect:
- Status = COMPLETED
- Track created
- Request closed
```

### What STAFF Can View
- ✅ All requests (to see workload)
- ✅ Own assignments
- ✅ Request timelines
- ✅ Store requests for assigned requests
- ✅ Chat messages for APPROVED store requests
- ❌ User management
- ❌ Role management
- ❌ Create assignments
- ❌ Delete requests

### Permissions Summary
| Action | Allowed |
|--------|---------|
| View All Requests | ✅ |
| Update Assigned Requests | ✅ |
| Create Store Requests | ✅ |
| Chat with Store | ✅ (APPROVED only) |
| View Own Assignments | ✅ |
| Delete Requests | ❌ |
| Create Assignments | ❌ |
| Manage Roles | ❌ |
| Respond to Store Requests | ❌ |

---

## STORE Role Flow

### Overview
Store personnel who manage equipment and supply requests from staff.

### Accessible Endpoints

#### Profile
- `GET /api/v1/users/me` - View own profile

#### Store Request Management
- `GET /api/v1/store-requests/` - View all store requests (paginated)
- `GET /api/v1/store-requests/status/{status}` - Filter by status (PENDING/APPROVED/REJECTED/FULFILLED)
- `GET /api/v1/store-requests/parent/{parent_request_id}` - View by parent request
- `GET /api/v1/store-requests/{store_request_id}` - View details
- `POST /api/v1/store-requests/{store_request_id}/respond` - Respond (approve/reject/fulfill)
- `PUT /api/v1/store-requests/{store_request_id}` - Update store request
- `POST /api/v1/store-requests/{store_request_id}/chat` - Send chat message (APPROVED only)
- `GET /api/v1/store-requests/{store_request_id}/chat` - View chat messages

#### Request Viewing (Context)
- `GET /api/v1/requests/{request_id}` - View parent request details
- `GET /api/v1/requests/{request_id}/comments` - View parent request timeline
- `POST /api/v1/requests/{request_id}/comments` - Add track entry

#### Request Types (Read-Only)
- `GET /api/v1/types/main` - View all main types
- `GET /api/v1/types/main/{main_type_id}/sub` - View sub types

### Typical Workflows

#### 1. Viewing Pending Store Requests
```
1. View pending requests → GET /api/v1/store-requests/status/PENDING
2. View specific request → GET /api/v1/store-requests/{store_request_id}
3. View parent request context → GET /api/v1/requests/{parent_request_id}
```

#### 2. Responding to Store Request

**Option A: APPROVE**
```
POST /api/v1/store-requests/{store_request_id}/respond
Body: {
  "status": "APPROVED",
  "response_comment": "Items available, preparing for pickup"
}

Effect:
- Store request status = APPROVED
- Track created: action_type="STORE_REQUEST_APPROVED"
- Chat becomes available for STAFF ↔ STORE communication
- responded_by set to store user ID
```

**Option B: REJECT**
```
POST /api/v1/store-requests/{store_request_id}/respond
Body: {
  "status": "REJECTED",
  "response_comment": "Items out of stock, expected in 2 weeks"
}

Effect:
- Store request status = REJECTED
- Track created: action_type="STORE_REQUEST_REJECTED"
- Request closed
- responded_by set to store user ID
```

#### 3. Communicating with Staff (APPROVED Requests)
```
After approving:

1. View chat → GET /api/v1/store-requests/{store_request_id}/chat

2. Send message → POST /api/v1/store-requests/{store_request_id}/chat
   Body: {
     "message": "Items ready for pickup at counter 3"
   }

3. Staff responds in chat

4. Coordinate delivery/pickup
```

#### 4. Marking as Fulfilled
```
After items delivered:

POST /api/v1/store-requests/{store_request_id}/respond
Body: {
  "status": "FULFILLED",
  "response_comment": "Items delivered to staff member"
}

Effect:
- Store request status = FULFILLED
- Track created: action_type="STORE_REQUEST_FULFILLED"
- Store request closed
```

### What STORE Can View
- ✅ All store requests
- ✅ Parent request details (for context)
- ✅ Chat messages for APPROVED store requests
- ✅ Request types
- ❌ All requests (only parent requests of store requests)
- ❌ User management
- ❌ Role management
- ❌ Assignments
- ❌ Create store requests (only STAFF can)

### Permissions Summary
| Action | Allowed |
|--------|---------|
| View Store Requests | ✅ |
| Respond to Store Requests | ✅ |
| Chat with Staff | ✅ (APPROVED only) |
| View Parent Requests | ✅ (context only) |
| Create Store Requests | ❌ |
| Delete Store Requests | ❌ |
| Manage Roles | ❌ |
| Manage Assignments | ❌ |

---

## Request Status Flow Summary

### Main Request Lifecycle
```
RAISED (USER creates)
  ↓
  ├─→ REJECTED (ADMIN rejects)
  ├─→ REPLIED (ADMIN replies) → USER updates → RAISED
  └─→ ASSIGNED (ADMIN assigns)
      ↓
      ├─→ REASSIGN_REQUESTED (STAFF can't handle) → back to ADMIN
      └─→ IN_PROGRESS (STAFF working)
          ↓
          COMPLETED (STAFF finishes)
```

### Store Request Lifecycle
```
PENDING (STAFF creates)
  ↓
  ├─→ REJECTED (STORE rejects)
  └─→ APPROVED (STORE approves)
      ↓
      [Chat available between STAFF ↔ STORE]
      ↓
      FULFILLED (STORE delivers)
```

---

## Track Action Types Reference

| Action Type | Who Creates | When |
|-------------|-------------|------|
| RAISED | USER | Request created |
| REPLIED | ADMIN | Admin responds to user |
| REJECTED | ADMIN | Request rejected |
| ASSIGNED | ADMIN | Request assigned to staff |
| REASSIGN_REQUESTED | STAFF | Staff requests reassignment |
| IN_PROGRESS | STAFF | Staff starts work |
| COMPLETED | STAFF | Request completed |
| USER_UPDATED | USER | User updates request after REPLIED |
| STORE_REQUEST_CREATED | STAFF | Store request created |
| STORE_REQUEST_APPROVED | STORE | Store approves request |
| STORE_REQUEST_REJECTED | STORE | Store rejects request |
| STORE_REQUEST_FULFILLED | STORE | Store delivers items |

---

## Common Scenarios

### Scenario 1: Simple Request Resolution
```
1. USER creates request → RAISED
2. ADMIN assigns to STAFF → ASSIGNED
3. STAFF starts work → IN_PROGRESS
4. STAFF completes → COMPLETED
```

### Scenario 2: Request Needs Clarification
```
1. USER creates request → RAISED
2. ADMIN needs more info → REPLIED
3. USER updates request → RAISED
4. ADMIN assigns to STAFF → ASSIGNED
5. STAFF completes → COMPLETED
```

### Scenario 3: Request with Equipment Needs
```
1. USER creates request → RAISED
2. ADMIN assigns to STAFF → ASSIGNED
3. STAFF starts work → IN_PROGRESS
4. STAFF creates store request → PENDING
5. STORE approves → APPROVED
6. STAFF and STORE chat about delivery
7. STORE delivers → FULFILLED
8. STAFF completes main request → COMPLETED
```

### Scenario 4: Request Reassignment
```
1. USER creates request → RAISED
2. ADMIN assigns to STAFF A → ASSIGNED
3. STAFF A can't handle → REASSIGN_REQUESTED
4. ADMIN assigns to STAFF B → ASSIGNED
5. STAFF B completes → COMPLETED
```

---

## Notes

- All endpoints require Firebase authentication token
- Tracks are ordered chronologically (created_at ASC)
- Multiple staff can be assigned to same request (atomic operations)
- Store chat only available for APPROVED store requests
- Old requests can be marked inactive (is_active = "false")
- All status changes create corresponding track entries
