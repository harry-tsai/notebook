# Wireframe

https://www.figma.com/board/WVmwn7pETlWmB8cHrEJcUi/Product-Team_Festure?node-id=547-15384&t=UEVYzcwFkvGzVm6s-0

# API Design

## Flow

```mermaid
graph TD
    A[Frontend]
    subgraph Admin User API
        BA[GET /admin/users] --> BB[取得管理者列表]
        BC[POST /admin/users/save] --> BD[儲存管理者]
        BE[GET /admin/users/email/:email] --> BF[email 查詢管理者]
    end

    A --> BA
    A --> BC
    A --> BE

    subgraph Admin IAM User Role API
        CA[GET /admin/iam/user_roles] --> CB[查詢角色設定列表]
        CC[POST /admin/iam/user_roles/save] --> CD[儲存角色使用者]
    end

    A --> CA
    A --> CC

    subgraph Admin IAM Role Permission API
        DA[GET /admin/iam/role_permissions] --> DB[查詢角色權限列表]
        DC[POST /admin/iam/role_permissions/save] --> DD[儲存角色權限]
    end

    A --> DA
    A --> DC
```

## Endpoints

### Admin User API

#### GET /admin/users

- **Description**: 取得管理者列表
- **Response**:

```json
{
  "users": [
    {
      "id": "string(uuid)",
      "email": "string",
      "name": "string",
      "admin_name": "string",
      "permissions": [
        {
          "resource_type": "string (e.g. admin.reward_dispatch, admin.permission_management.account_settings ...)",
          "actions": ["string (e.g. edit, create, delete, view)"]
        }
      ]
    }
  ]
}
```

- **HTTP Status Codes**:
  - `200 OK`

#### POST /admin/users/save

- **Description**: 儲存管理者
- **Request Body**:

```json
{
  "add_users": [
    {
      "user_id": "string",
      "admin_name": "string"
    }
  ],
  "remove_users": ["string(user_id)"],
  "update_users": [
    {
      "user_id": "string",
      "admin_name": "string"
    }
  ]
}
```

- **HTTP Status Codes**:
  - `204 No Content`
  - `404 Not Found`: User not found

#### GET /admin/users/email/:email

- **Description**: email 查詢管理者 (User Object)
- **Response**:

```json
{
  "id": "string(uuid)",
  "email": "string",
  "name": "string",
  "admin_name": "string",
  "permissions": [
    {
      "resource_type": "string (e.g. admin.reward_dispatch, admin.permission_management.account_settings ...)",
      "actions": ["string (e.g. edit, create, delete, view)"]
    }
  ]
}
```

- **HTTP Status Codes**:
  - `200 OK`
  - `404 Not Found`

### IAM User Role API

#### GET /admin/iam/user_roles

- **Description**: 查詢角色設定列表
- **Response**:

```json
{
  "roles": [
    {
      "id": "int",
      "name": "string (e.g. Admin, Team Lead)",
      "users": [
        {
          "id": "string(uuid)",
          "email": "string",
          "admin_name": "string"
        }
      ]
    }
  ]
}
```

- **HTTP Status Codes**:
  - `200 OK`

#### POST /admin/iam/user_roles/save

- **Description**: 儲存角色使用者
- **Request Body**:

```json
{
  "add": [
    {
      "role_id": "int",
      "user_id": "string(uuid)"
    }
  ],
  "remove": [
    {
      "role_id": "int",
      "user_id": "string(uuid)"
    }
  ]
}
```

- **HTTP Status Codes**:
  - `204 No Content`
  - `404 Not Found`: Role not found / User not found

### IAM Role Permission API

#### GET /admin/iam/role_permissions

- **Description**: 查詢角色權限列表
- **Response**:

```json
{
  "roles": [
    {
      "id": "int",
      "name": "string (e.g. Admin, Team Lead)",
      "permissions": [
        {
          "id": "int",
          "resource_type": "string (e.g. admin.reward_dispatch, admin.permission_management.account_settings ...)",
          "actions": ["string (e.g. edit, create, delete, view)"]
        }
      ]
    }
  ]
}
```

- **HTTP Status Codes**:
  - `200 OK`

#### POST /admin/iam/role_permissions/save

- **Description**: 儲存角色權限
- **Request Body**:

```json
{
  "add": [
    {
      "role_id": "int",
      "permission_id": "int"
    }
  ],
  "remove": [
    {
      "role_id": "int",
      "permission_id": "int"
    }
  ]
}
```

- **HTTP Status Codes**:
  - `204 No Content`
  - `404 Not Found`: Role not found / Permission not found

## Note

- Return 403 Forbidden if the user does not have permission to access the admin endpoint.
- `resource_type` is a string enum
  - `admin.reward_dispatch`: 派獎系統
  - `admin.permission_management.account_settings`: 帳號設定
  - `admin.permission_management.user_roles`: 角色設定
  - `admin.permission_management.role_permissions`: 角色權限

# Backend Design

## Database Schema

```mermaid
erDiagram
    users 1--many(0) user_roles : has
    roles 1--many(0) user_roles : has
    roles 1--many(0) role_permissions : has
    permissions 1--many(0) role_permissions : grants

    users {
        string(uuid) id PK
        string name
        string admin_name
    }

    roles {
        int id PK
        string name
    }

    permissions {
        int id PK
        string resource_type "admin.reward_dispatch, admin.permission_management.account_settings ..."
        string action "1: edit 2: create 3: delete 4: view"
    }

    user_roles {
        int id PK
        string(uuid) user_id FK
        int role_id FK
    }

    role_permissions {
        int id PK
        int role_id FK
        int permission_id FK
    }
```

### Tables

#### user_roles

- Unique key: (user_id, role_id)

#### role_permissions

- Unique key: (role_id, permission_id)

### Notes

- Adopt cache for above tables to improve performance.

## High-Level Design

### **[Store] User**

#### GetByEmail(context ctx.CTX, email string) (\*models.User, error)

- Caller
  - api: `admin/users/email/:email` to retrieve user information.
    - should filter out the user `is_admin = 0`.

#### decorate(context ctx.CTX, user \*models.User)

- Calls IAM store to fetch permissions and decorate the user object with permissions.

#### [New] GetAdmins(context ctx.CTX) ([]\*models.User, error)

- Fetch all users with `is_admin = 1` from the database.
- Caller
  - api: `admin/users/

### **[New] [Store] IAM**

This store will handle all IAM related operations, including admin, role, and permission management.

#### GetPermissionsByUser(context ctx.CTX, userID string) (\*models.Permissions, error)

- Query the database to get all roles for the user.
- For each role, fetch the permissions associated with it.
- Return a `models.Permissions` object containing the permissions.
- Called by User store's `decorate` method to add permissions to the user object.
