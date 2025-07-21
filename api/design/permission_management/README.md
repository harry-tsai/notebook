# API Design

## Flow

```mermaid
graph TD
    A[Frontend]
    subgraph Admin User API
        B[PATCH /admin/users/:id] --> C[設定管理者暱稱]
        D[GET /admin/users/email/:email] --> E[email 查詢管理者]
    end

    A --> B
    A --> D

    subgraph Permission Management API
        F[GET /admin/perm_mgt/user_roles] --> G[查詢角色設定列表]
        H[PATCH /admin/perm_mgt/role/:id] --> I[編輯角色設定]

        J[GET /admin/perm_mgt/role_permissions] --> K[查詢角色權限列表]
        L[PATCH /admin/perm_mgt/role_permissions] --> M[更新角色權限]
    end

    A --> F
    A --> H
    A --> J
    A --> L
```

## Endpoints

### Admin User API

#### PATCH /admin/users/:id

- **Description**: 設定使用者資料 (管理者暱稱)
- **Request Body**:

```json
{
  "admin_name": "string"
}
```

- **HTTP Status Codes**:
  - `204 No Content`

#### GET /admin/users/email/:email

- **Description**: 根據 email 查詢使用者資料
- **Response**:

```json
{
  "id": "string(uuid)",
  "email": "string",
  "name": "string",
  "admin_name": "string"
}
```

- **HTTP Status Codes**:
  - `200 OK`
  - `404 Not Found`

### Permission Management API

#### GET /admin/perm_mgt/user_roles

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

#### PATCH /admin/perm_mgt/role/:id

- **Description**: 編輯角色設定
- **Request Body**:

```json
{
  "added_user_ids": ["string(user_id, 新增管理者)"],
  "removed_user_ids": ["string(user_id, 刪除管理者)"]
}
```

- **HTTP Status Codes**:
  - `204 No Content`
  - `404 Not Found`: Role not found / User not found

#### GET /admin/perm_mgt/role_permissions

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
          "resource_type": "string (e.g. admin.reward_dispatch, admin.permission_management)",
          "action": "string (e.g. edit, create, delete, view, hidden)"
        }
      ]
    }
  ]
}
```

- **HTTP Status Codes**:
  - `200 OK`

#### PATCH /admin/perm_mgt/role_permissions

- **Description**: 更新角色權限
- **Request Body**:

```json
{
  "added": [
    {
      "role_id": "int",
      "resource_type": "string (e.g. admin.reward_dispatch, admin.permission_management)",
      "action": "string (e.g. edit, create, delete, view, hidden)"
    }
  ],
  "removed": [
    {
      "role_id": "int",
      "resource_type": "string (e.g. admin.reward_dispatch, admin.permission_management)",
      "action": "string (e.g. edit, create, delete, view, hidden)"
    }
  ]
}
```

- **HTTP Status Codes**:
  - `204 No Content`
  - `404 Not Found`: Role not found / Permission not found

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
        string resource_type "1: admin.reward_dispatch 2: admin.permission_management"
        string action "1: edit 2: create 3: delete 4: view 5: hidden"
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
