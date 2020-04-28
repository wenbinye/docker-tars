# Tars Dockerfile
Tars Dockerfile

start like:

```yml
version: '3'

services:
  mysql:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: "Pa$sw0rd"
    volumes:
      - ./mysql-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin" ,"ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
  tars:
    image: wenbinye/tars
    ports:
      - '3000:3000'
      - '3001:3001'
    environment:
      MYSQL_HOST: 'mysql'
      MYSQL_ROOT_PASSWORD: 'Pa$sw0rd'
      REBUILD: 'true'
    links:
      - mysql
    depends_on:
      - mysql
    volumes:
      - ./tars-data:/data/tars
```
