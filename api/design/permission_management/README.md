# Wireframe

https://www.figma.com/board/WVmwn7pETlWmB8cHrEJcUi/Product-Team_Festure?node-id=547-15384&t=UEVYzcwFkvGzVm6s-0

# API Design

## Flow

```mermaid
graph TD
    A[Frontend]
    subgraph Admin User API
        BA[POST /admin/users/update] --> BB[更新管理者]
        BG[GET /admin/users/email/:email] --> BH[email 查詢管理者]
    end

    A --> BA
    A --> BG

    subgraph Admin IAM User Role API
        CA[GET /admin/iam/user_roles] --> CB[查詢角色設定列表]
        CC[POST /admin/iam/user_roles/update] --> CD[更新角色使用者]
    end

    A --> CA
    A --> CC

    subgraph Admin IAM Role Permission API
        DA[GET /admin/iam/role_permissions] --> DB[查詢角色權限列表]
        DC[POST /admin/iam/role_permissions/update] --> DD[更新角色權限]
    end

    A --> DA
    A --> DC
```

## Endpoints

### Admin User API

#### POST /admin/users/update

- **Description**: 更新管理者
- **Request Body**:

```json
{
  "added_users": [
    {
      "user_id": "string",
      "admin_name": "string"
    }
  ],
  "removed_users": ["string(user_id)"]
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

#### POST /admin/iam/user_roles/update

- **Description**: 更新角色使用者
- **Request Body**:

```json
{
  "added": [
    {
      "role_id": "int",
      "user_id": "string(uuid)"
    }
  ],
  "removed": [
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

#### POST /admin/iam/role_permissions/update

- **Description**: 更新角色權限
- **Request Body**:

```json
{
  "added": [
    {
      "role_id": "int",
      "permission_id": "int"
    }
  ],
  "removed": [
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

### user_roles

- Unique key: (user_id, role_id)

### role_permissions

- Unique key: (role_id, permission_id)
