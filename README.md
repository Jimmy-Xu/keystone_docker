# Keystone Docker Image

## Usage

```
sudo docker run -d -p 5000:5000 -p 35357:35357 tobegit3hub/keystone_docker
```

## Keystone Client

### API

```
curl -i \
  -H "Content-Type: application/json" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "admin",
          "domain": { "id": "default" },
          "password": "ADMIN_PASS"
        }
      }
    }
  }
}' \
  http://localhost:5000/v3/auth/tokens ; echo
```

Please make sure to create user by the following method. Then get the result like this.

```
HTTP/1.1 201 Created
X-Subject-Token: 210b7a7998ef49c89a8af437df580ff2
Vary: X-Auth-Token
Content-Type: application/json
Content-Length: 297
X-Openstack-Request-Id: req-e8bb5e61-fd49-4d94-bfe6-bed5bbd489e8
Date: Wed, 20 May 2015 03:25:03 GMT

{"token": {"methods": ["password"], "expires_at": "2015-05-20T04:25:03.434048Z", "extras": {}, "user": {"domain": {"id": "default", "name": "Default"}, "id": "6c12289f2324405aaa068da611a8fad0", "name": "admin"}, "audit_ids": ["HdzDomPTQFym7f7zVFMvAA"], "issued_at": "2015-05-20T03:25:03.434092Z"}}
```

### Client

```
➜  keystone_docker git:(master) ✗ source keystone.rc
➜  keystone_docker git:(master) ✗ keystone user-list
+----------------------------------+-------+---------+-------------------+
|                id                |  name | enabled |       email       |
+----------------------------------+-------+---------+-------------------+
| 6c12289f2324405aaa068da611a8fad0 | admin |   True  | admin@example.com |
+----------------------------------+-------+---------+-------------------+
```

### Client In Container

```
➜  docker exec -i -t 6d71a86863ff /bin/bash

root@6d71a86863ff:/keystone# export OS_SERVICE_TOKEN=ADMIN
root@6d71a86863ff:/keystone# export OS_SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0

root@6d71a86863ff:/keystone# keystone user-create --name=admin --pass=ADMIN_PASS --email=admin@example.com
+----------+----------------------------------+
| Property |              Value               |
+----------+----------------------------------+
|  email   |        admin@example.com         |
| enabled  |               True               |
|    id    | 6c12289f2324405aaa068da611a8fad0 |
|   name   |              admin               |
| username |              admin               |
+----------+----------------------------------+

root@6d71a86863ff:/keystone# keystone user-list
+----------------------------------+-------+---------+-------------------+
|                id                |  name | enabled |       email       |
+----------------------------------+-------+---------+-------------------+
| 6c12289f2324405aaa068da611a8fad0 | admin |   True  | admin@example.com |
+----------------------------------+-------+---------+-------------------+
```	