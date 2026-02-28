# User Roles & Permissions

This document details what each user role can do in the system.

---

## Role Overview

The system has 4 distinct user roles:

1. **USER** - Regular users who create and track requests
2. **ADMIN** - System administrators with full access
3. **STAFF** - Technical staff who handle assigned requests
4. **STORE** - Store personnel who manage equipment requests

---

## 1. USER Role

**Purpose:** Regular users who need to submit and track requests/tickets.

### What USER Can Do:

#### ✅ CREATE Operations

1. **Create Requests**
   - Submit new tickets/requests
   - Must provide main type, sub type, and description
   - Request automatically gets status "RAISED"
   - Can only create requests for themselves

2. **Add Comments**
   - Reply to any request they can view
   - Add notes or updates to requests
   - Comment types: REPLY, NOTE

#### ✅ READ Operations

1. **View Own Requests**
   - See all requests they created
   - View request details (status, description, timestamps)
   - Cannot see other users' requests

2. **View Request Details**
   - See specific request by ID (if they have access)
   - View all comments on a request
   - See request timeline

3. **View Request Types**
   - See all main types (for dropdown selection)
   - See all sub types for a main type
   - View type details

#### ✅ UPDATE Operations

**NONE** - Users cannot update requests directly. They can only:
- Add comments to communicate updates
- Request changes through comments

#### ✅ DELETE Operations

**NONE** - Users cannot delete anything

### What USER Cannot Do:

❌ Update request status
❌ Assign requests to staff
❌ Delete requests
❌ Manage roles
❌ Create/modify request types
❌ View other users' requests
❌ Create store requests
❌ View assignments
❌ Access admin functions

### Typical USER Workflow:

1. Login with Firebase authentication
2. Browse available request types
3. Create new request with description
4. Track request status
5. View and reply to comments from ADMIN/STAFF
6. Wait for resolution

---

## 2. ADMIN Role

**Purpose:** System administrators who manage the entire system.

### What ADMIN Can Do:

#### ✅ CREATE Operations

1. **Create Roles**
   - Assign roles to users by email
   - Bulk create/update roles
   - Grant access to new users

2. **Create Request Types**
   - Create new main types
   - Create new sub types
   - Organize request categorization

3. **Create Assignments**
   - Assign requests to staff members
   - Reassign requests to different staff
   - Manage workload distribution

4. **Add Comments**
   - Comment on any request
   - Provide updates to users
   - Internal notes for staff

#### ✅ READ Operations

1. **View All Requests**
   - See every request in the system
   - Filter and paginate through requests
   - View request details and history

2. **View All Roles**
   - See all user role assignments
   - Check who has what access
   - Audit user permissions

3. **View All Assignments**
   - See all staff assignments
   - View assignment history
   - Check staff workload

4. **View All Store Requests**
   - See all equipment requests
   - Monitor store operations
   - Track equipment fulfillment

5. **View Request Types**
   - See all main and sub types
   - View type details

6. **View Comments**
   - See all comments on any request
   - Monitor communication

#### ✅ UPDATE Operations

1. **Update Requests**
   - Change request status
   - Modify request details
   - Progress requests through workflow
   - Available statuses:
     - RAISED → REPLIED
     - RAISED → REJECTED
     - RAISED → ASSIGNED
     - ASSIGNED → IN_PROGRESS
     - IN_PROGRESS → COMPLETED
     - IN_PROGRESS → REASSIGN_REQUESTED

2. **Update Roles**
   - Change user roles
   - Promote/demote users
   - Modify access permissions

3. **Update Request Types**
   - Rename main types
   - Rename sub types
   - Reorganize categories

4. **Update Assignments**
   - Modify assignment details
   - Activate/deactivate assignments
   - Change assignment status

5. **Update Store Requests**
   - Modify store request details
   - Change status
   - Add response comments

#### ✅ DELETE Operations

1. **Delete Requests**
   - Permanently remove requests
   - CASCADE: Also deletes all comments, assignments, and store requests
   - Use with caution - cannot be undone

2. **Delete Roles**
   - Remove user access
   - Revoke permissions
   - User can no longer login

3. **Delete Request Types**
   - Remove main types (CASCADE: deletes all sub types)
   - Remove sub types
   - May break existing requests

4. **Delete Assignments**
   - Remove staff assignments
   - Clean up assignment history

5. **Delete Store Requests**
   - Remove equipment requests
   - Clean up store data

### What ADMIN Cannot Do:

❌ Nothing - ADMIN has full system access

### Typical ADMIN Workflow:

1. Manage user roles and access
2. Create and organize request types
3. Monitor all incoming requests
4. Assign requests to appropriate staff
5. Update request statuses
6. Handle escalations
7. Delete inappropriate or duplicate requests
8. Generate reports (view all data)
9. Manage system configuration

---

## 3. STAFF Role

**Purpose:** Technical staff who handle and resolve assigned requests.

### What STAFF Can Do:

#### ✅ CREATE Operations

1. **Create Store Requests**
   - Request equipment/supplies from store
   - Link to parent request
   - Specify equipment needed
   - Status automatically set to "PENDING"

2. **Add Comments**
   - Comment on any request they can view
   - Provide updates to users
   - Document work progress
   - Request reassignment

#### ✅ READ Operations

1. **View All Requests**
   - See every request in the system
   - Filter and paginate through requests
   - View request details

2. **View Own Assignments**
   - See requests assigned to them
   - Filter for active assignments only
   - Check workload

3. **View All Assignments**
   - See all staff assignments
   - View who is assigned to what
   - Check team workload

4. **View Store Requests**
   - See store requests they created
   - View store requests for their assigned requests
   - Track equipment status

5. **View Request Types**
   - See all main and sub types
   - Understand request categories

6. **View Comments**
   - See all comments on requests
   - Follow conversation history

#### ✅ UPDATE Operations

1. **Update Requests**
   - Change request status
   - Update request details
   - Progress requests through workflow
   - Mark as IN_PROGRESS or COMPLETED
   - Request reassignment (REASSIGN_REQUESTED)

#### ✅ DELETE Operations

**NONE** - Staff cannot delete anything

### What STAFF Cannot Do:

❌ Create/delete roles
❌ Create/delete request types
❌ Create/delete assignments (cannot assign to themselves)
❌ Delete requests
❌ Delete store requests
❌ Update/delete other staff's assignments
❌ Respond to store requests (only STORE can)
❌ Bulk operations

### Typical STAFF Workflow:

1. Login and view assigned requests
2. Check request details and comments
3. Update request status to IN_PROGRESS
4. If equipment needed:
   - Create store request
   - Wait for store approval
5. Work on resolving the request
6. Add progress comments
7. Update status to COMPLETED when done
8. If cannot handle:
   - Add comment explaining why
   - Update status to REASSIGN_REQUESTED

---

## 4. STORE Role

**Purpose:** Store personnel who manage equipment and supply requests.

### What STORE Can Do:

#### ✅ CREATE Operations

1. **Add Comments**
   - Comment on any request
   - Provide equipment availability updates
   - Document delivery status

#### ✅ READ Operations

1. **View All Store Requests**
   - See all equipment requests
   - Filter by status (PENDING, APPROVED, REJECTED, FULFILLED)
   - Paginate through requests

2. **View Store Requests by Status**
   - Filter pending requests
   - See approved requests
   - Track fulfilled requests

3. **View Store Request Details**
   - See specific store request
   - View requester information
   - Check parent request context

4. **View Store Requests by Parent**
   - See all equipment requests for a ticket
   - Understand full equipment needs

5. **View Request Details**
   - See parent request details
   - Understand context for equipment needs

6. **View Request Types**
   - See all main and sub types
   - Understand request categories

7. **View Comments**
   - See comments on requests
   - Follow conversation

#### ✅ UPDATE Operations

1. **Respond to Store Requests**
   - Approve equipment requests
   - Reject equipment requests
   - Mark as fulfilled when delivered
   - Add response comments
   - Available statuses:
     - PENDING → APPROVED
     - PENDING → REJECTED
     - APPROVED → FULFILLED

2. **Update Store Requests**
   - Modify store request details
   - Update status
   - Add notes

#### ✅ DELETE Operations

**NONE** - Store personnel cannot delete anything

### What STORE Cannot Do:

❌ Create/delete roles
❌ Create/delete request types
❌ Create/delete assignments
❌ Create/delete requests
❌ Create store requests (only STAFF can)
❌ Delete store requests
❌ Update main requests
❌ Assign staff to requests

### Typical STORE Workflow:

1. Login and view pending store requests
2. Check equipment availability
3. Review request details
4. Respond to request:
   - APPROVED if items available
   - REJECTED if items unavailable
5. Prepare and deliver items
6. Update status to FULFILLED
7. Add delivery notes in comments

---

## Permission Matrix

| Operation | USER | ADMIN | STAFF | STORE |
|-----------|------|-------|-------|-------|
| **Requests** |
| Create Request | ✅ | ❌ | ❌ | ❌ |
| View Own Requests | ✅ | ✅ | ✅ | ✅ |
| View All Requests | ❌ | ✅ | ✅ | ✅ |
| Update Request | ❌ | ✅ | ✅ | ❌ |
| Delete Request | ❌ | ✅ | ❌ | ❌ |
| **Comments** |
| Add Comment | ✅ | ✅ | ✅ | ✅ |
| View Comments | ✅ | ✅ | ✅ | ✅ |
| **Roles** |
| Create Role | ❌ | ✅ | ❌ | ❌ |
| View Roles | ❌ | ✅ | ❌ | ❌ |
| Update Role | ❌ | ✅ | ❌ | ❌ |
| Delete Role | ❌ | ✅ | ❌ | ❌ |
| Bulk Roles | ❌ | ✅ | ❌ | ❌ |
| **Request Types** |
| View Types | ✅ | ✅ | ✅ | ✅ |
| Create Type | ❌ | ✅ | ❌ | ❌ |
| Update Type | ❌ | ✅ | ❌ | ❌ |
| Delete Type | ❌ | ✅ | ❌ | ❌ |
| **Assignments** |
| View Assignments | ❌ | ✅ | ✅ | ❌ |
| Create Assignment | ❌ | ✅ | ❌ | ❌ |
| Update Assignment | ❌ | ✅ | ❌ | ❌ |
| Delete Assignment | ❌ | ✅ | ❌ | ❌ |
| **Store Requests** |
| Create Store Request | ❌ | ❌ | ✅ | ❌ |
| View Store Requests | ❌ | ✅ | ✅ | ✅ |
| Update Store Request | ❌ | ✅ | ❌ | ✅ |
| Respond to Store Request | ❌ | ❌ | ❌ | ✅ |
| Delete Store Request | ❌ | ✅ | ❌ | ❌ |

---

## Request Status Flow

### USER Perspective:
```
RAISED (created by user)
  ↓
REPLIED (admin/staff responded) → User can reply back
  ↓
ASSIGNED (assigned to staff)
  ↓
IN_PROGRESS (staff working on it)
  ↓
COMPLETED (resolved)

OR

RAISED → REJECTED (admin/staff rejected)
```

### STAFF Perspective:
```
ASSIGNED (received assignment)
  ↓
IN_PROGRESS (started working)
  ↓
[Create Store Request if equipment needed]
  ↓
COMPLETED (finished)

OR

IN_PROGRESS → REASSIGN_REQUESTED (cannot handle)
```

### STORE Perspective:
```
PENDING (staff created store request)
  ↓
APPROVED (store approved)
  ↓
FULFILLED (items delivered)

OR

PENDING → REJECTED (items unavailable)
```

---

## Access Control Rules

### Authentication
- All endpoints require Firebase authentication token
- Token must be valid and not expired
- User must have a role assigned in the database

### Authorization
- Each endpoint checks for specific roles
- 403 error if user doesn't have required role
- 401 error if token is invalid
- 403 error if no role assigned to email

### Data Access
- **USER**: Can only see their own requests
- **ADMIN**: Can see everything
- **STAFF**: Can see all requests and assignments
- **STORE**: Can see all store requests and related requests

### Cascade Deletes
Only ADMIN can delete, and deletions cascade:
- Delete Request → Deletes comments, assignments, store requests
- Delete Main Type → Deletes all sub types under it
- Delete Role → User loses access but data remains

---

## Security Notes

1. **Firebase Authentication Required**
   - All API calls must include valid Firebase token
   - Token verified on every request

2. **Role-Based Access Control**
   - Roles checked before any operation
   - Unauthorized access returns 403

3. **Data Isolation**
   - Users can only see their own data
   - Staff/Store see relevant data only
   - Admin sees everything

4. **Audit Trail**
   - All creates include creator ID
   - All updates include timestamp
   - Comments track sender and role

5. **Validation**
   - Foreign keys validated before creation
   - Status transitions validated
   - Data types enforced

---

## Best Practices

### For USERS:
- Provide detailed descriptions in requests
- Use comments to provide updates
- Check request status regularly
- Reply promptly to admin/staff questions

### For ADMINS:
- Assign requests promptly
- Monitor request queue
- Use appropriate status transitions
- Be cautious with delete operations
- Regularly review role assignments

### For STAFF:
- Update request status as you work
- Create store requests early if equipment needed
- Add progress comments regularly
- Request reassignment if cannot handle
- Mark completed when done

### For STORE:
- Respond to store requests promptly
- Provide clear response comments
- Update to FULFILLED when delivered
- Reject with explanation if unavailable
- Monitor pending requests queue
