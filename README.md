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

## 目录说明

/data/tars 是 docker volume 用于放所有运行时数据
/root/.bashrc 添加 nvm 环境变量
/root/.nvm nvm 安装目录
/usr/local/app/web web 安装目录
/usr/local/app/tars tars 安装系统安装目录
/usr/local/app/tars/deploy 部署需要的原文件

deploy/framework/sql 中路径相关已经替换

## 调试脚本


export MYSQL_ROOT_PASSWORD=vv123456
bash -x ./rebuild.sh 
cd /build/tars/cpp/deploy
