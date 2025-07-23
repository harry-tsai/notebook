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

    subgraph Admin IAM Role User API
        CA[GET /admin/iam/role_users] --> CB[查詢角色設定列表]
        CC[POST /admin/iam/role_users/save] --> CD[儲存角色使用者]
    end

    A --> CA
    A --> CC

    subgraph Admin IAM Role Permission API
        DA[GET /admin/iam/role_permissions] --> DB[查詢角色權限列表]
        DC[POST /admin/iam/role_permissions/save] --> DD[儲存角色權限]
        DE[GET /admin/iam/permissions] --> DF[取得權限列表]
    end

    A --> DA
    A --> DC
```

## API Specification

PR: https://github.com/17media/wave-openapi/pull/6

### Note

- Return 403 Forbidden if the user does not have permission to access the admin endpoint.

# Backend Design

## Database Schema

```mermaid
erDiagram
    Users 1--many(0) RoleUsers : has
    Roles 1--many(0) RoleUsers : has
    Roles 1--many(0) RolePermissions : has
    Permissions 1--many(0) RolePermissions : grants

    Users {
        string(uuid) id PK
        string name
        string adminName
    }

    Roles {
        int id PK
        string name
    }

    Permissions {
        int id PK
        string resourceType "admin.reward_dispatch, admin.permission_management.account_settings ..."
        string action "1: edit 2: create 3: delete 4: view"
    }

    RoleUsers {
        int id PK
        int roleID FK
        string(uuid) userID FK
    }

    RolePermissions {
        int id PK
        int roleID FK
        int permissionID FK
    }
```

### Tables

#### RoleUsers

- Unique key: (userID, roleID)

#### RolePermissions

- Unique key: (roleID, permissionID)

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

### Middleware

Middleware to check if the user has permission to access the admin endpoint.
