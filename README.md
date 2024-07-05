本项目旨在升级适用于 CentOS 的 OpenSSH 包。通过此项目，您可以轻松地安装最新版本的 OpenSSH。

OpenSSH 是一个免费的 SSH 连接工具，广泛用于安全的远程登录和文件传输。本项目提供了RPM包的形式对OpenSSH进行升级，以确保您使用的是最新版本。

## 特性

- 升级到最新版本的 OpenSSH
- 提供 RPM 包
- 支持 CentOS 系统

## 安装

没什么好说的，升级完成以后执行
```bash
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
chmod 600 /etc/ssh/ssh_host_*_key
systemctl restart sshd
```

## 使用

安装完成后，您可以使用以下命令启动 OpenSSH 服务：
```bash
sudo systemctl start sshd
sudo systemctl enable sshd
