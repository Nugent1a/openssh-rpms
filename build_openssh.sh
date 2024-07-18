#!/bin/bash

echo
echo '==============================================================================='
echo
echo Author: Nugent
echo Created Time: 2023/08/03
echo Updated Time: 2023/07/10
echo Release: 1.0_Bata
echo Script Description: OpenSSH rpmbuild
echo
echo '==============================================================================='


read -p $'\033[40;32m
帮助:

1、脚本用于升级OpenSSH源码包构建rpm包

已阅读并领会，请按回车键继续执行此脚本\033[0m
' STATEMENT

case $STATEMENT in
*)
echo -e "===============================================================================\n"
;;
esac
#清理
rm -rf /opt/openssh-*rpms
rm -rf /root/rpmbuild
#OpenSSH版本
OPENSSH_VERSION=9.8p1
#OpenSSH源码包目录
OPENSSH_DIR=$(find / -name openssh-$OPENSSH_VERSION.tar.gz)
#安装编译依赖组件
yum install -y rpm-build gcc gcc-c++ glibc glibc-devel perl pcre pcre-devel zlib zlib-devel make wget krb5-devel pam-devel libX11-devel libXt-devel initscripts libXt-devel gtk2-devel imake xmkmf
#建立编译目录
mkdir -pv /root/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
#解压spec编译文件
cd /root/rpmbuild/SOURCES/
cp $OPENSSH_DIR ./
tar -xf openssh-$OPENSSH_VERSION.tar.gz openssh-$OPENSSH_VERSION/contrib/redhat/openssh.spec
mv openssh-$OPENSSH_VERSION /root/rpmbuild/SPECS
#配置spec编译文件
cd /root/rpmbuild/SPECS/openssh-$OPENSSH_VERSION/contrib/redhat/
sed -i '/# OpenSSH privilege separation requires a user & group ID/a\%global debug_package %{nil}' openssh.spec
sed -i -e "s/%global no_gnome_askpass 0/%global no_gnome_askpass 1/g" openssh.spec
sed -i -e "s/%global no_x11_askpass 0/%global no_x11_askpass 1/g" openssh.spec
#使用OpenSSL编译
sed -i -e "s/%global without_openssl 1/%global without_openssl 0/g" openssh.spec
#跳过OpenSSL头文件检查
#sed -i '/--disable-strip /i \        --without-openssl-header-check \\' openssh.spec
#OpenSSL目录
sed -i '/--disable-strip /i \        --with-ssl-dir=/usr/openssl \\' openssh.spec

#启用多线程编译
sed -i 's/make/make -j$(nproc)/g' openssh.spec
#编译openssh源码
rpmbuild -bb /root/rpmbuild/SPECS/openssh-$OPENSSH_VERSION/contrib/redhat/openssh.spec
mkdir /opt/openssh-$OPENSSH_VERSION-rpms
mv /root/rpmbuild/RPMS/x86_64/* /opt/openssh-$OPENSSH_VERSION-rpms
#卸磨杀驴
rm -rf /root/rpmbuild
echo \nrpm文件在/opt/openssh-$OPENSSH_VERSION-rpms\n
