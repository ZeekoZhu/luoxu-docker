# Deploy luoxu with Docker/Podman

## 准备工作

首先，克隆本仓库，并初始化 Git 子模块：

```
git clone https://github.com/ZeekoZhu/luoxu-docker.git
git submodule update --init --recursive
```

然后，按照实际情况修改下面的文件：

- 将 `./luoxu-web/src/App.svelte` 中的 `LUOXU_URL` 改为将要部署的 luoxu 服务的 URL。
- 复制 `./luoxu/config.toml.example` 为 `./config.toml`，并按照其中的注释修改配置。

## 构建镜像并启动服务

```
podman-compose build
podman-compose up
```

## 登录 Telegram 帐号

服务启动后，你将会收到一条来自 Telegram 的登录确认消息，受到消息后，使用下面的命令输入验证码给 luoxu：

```
make enter INPUT=12345
```

输入验证码后，稍等一会儿，查看 luoxu-api 的日志输出：

```
podman-compose logs
```

如果看到跟 password 相关的日志输出，说明你需要输入密码：

```
make enter INPUT=your_password
```

大功告成，现在就等 luoxu 索引你的群聊历史了。
