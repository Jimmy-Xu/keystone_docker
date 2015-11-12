# Keystone Docker

## Introduction

This repo is the docker image of Liberty [Keystone](https://github.com/openstack/keystone).

## Usage

Run keystone in container.

```
docker run -d -p 5000:5000 -p 35357:35357 tobegit3hub/keystone_docker
```

## Client

Use keystone command-line client.

```
docker run -i -t --net=host tobegit3hub/keystone_docker bash
```

```
source openrc

keystone user-create --name=admin --pass=ADMIN_PASS --email=admin@example.com
+----------+----------------------------------+
| Property |              Value               |
+----------+----------------------------------+
|  email   |        admin@example.com         |
| enabled  |               True               |
|    id    | 6c12289f2324405aaa068da611a8fad0 |
|   name   |              admin               |
| username |              admin               |
+----------+----------------------------------+

keystone user-list
+----------------------------------+-------+---------+-------------------+
|                id                |  name | enabled |       email       |
+----------------------------------+-------+---------+-------------------+
| 6c12289f2324405aaa068da611a8fad0 | admin |   True  | admin@example.com |
+----------------------------------+-------+---------+-------------------+
```

Use keystone API.

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
