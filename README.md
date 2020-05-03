# Tars Dockerfile

和官方镜像相比，添加以下特性：

- 添加 [wait-for-it](https://github.com/vishnubob/wait-for-it.git) 可等 mysql 服务后才启动服务，防止错误退出
- 已经将文件放到安装位置，减少启动复制文件过程。启动时只是根据当前容器 ip 地址更新数据库和配置文件
- 数据库不再根据 REBUILD 变量初始化，启动时检查 db_tars 不存在才创建数据库，否则跳过数据库初始化

## 使用说明

推荐使用 docker-compose 启动服务：

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
    links:
      - mysql
    depends_on:
      - mysql
    volumes:
      - ./tars-data:/data/tars
```

强制初始化数据库：

```bash
docker run --link mysql:mysql -e MYSQL_HOST=mysql -e MYSQL_ROOT_PASSWORD=Pass wenbinye/tars rebuild
```

## 目录说明

- /data/tars 是 docker volume 用于放所有运行时数据
- /root/.bashrc 添加 nvm 环境变量
- /root/.nvm nvm 安装目录
- /usr/local/app/web web 安装目录
- /usr/local/app/tars tars 安装系统安装目录
- /usr/local/app/tars/deploy 部署需要的原文件

