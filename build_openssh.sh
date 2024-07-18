#!/bin/bash

clear
echo
echo '==============================================================================='
echo
echo Author: Nugent
echo Created Time: 2022/12/10
echo Updated Time: 2024/07/10
echo -e Release:1.5 "\n		\033[1;40;32m1、修复了一些已知问题\n		2、修改部分文字说明\033[0m"
echo Script Description: build_openssh-rpms
echo
echo '==============================================================================='

OS=$(grep '^NAME=' /etc/os-release | sed 's/^NAME="\([^"]*\)"/\1/')
#OpenSSH版本
OPENSSH_VERSION=9.8p1

read -p '
帮助:

1、脚本用构建OpenSSL和OpenSSH的rpm包

2、升级版本前请提前做好数据备份（运营商拍快照/开通telnet）

已阅读并领会，请按回车键继续执行此脚本
' STATEMENT

case $STATEMENT in
*)
echo -e "===============================================================================\n"
;;
esac

rm -rf /root/rpmbuild

read -p "是否安装依赖

1、安装(需要yun源可用)
2、忽略(可能编译失败)

请选择:" VALUE

echo
case $VALUE in
"1")
#yum -y remove openssl
yum -y install \
    curl \
    which \
    make \
    gcc \
    gcc-c++ \
    glibc \
    glibc-devel \
    perl \
    pcre \
    pcre-devel \
    zlib \
    zlib-devel \
    wget \
    krb5-devel \
    pam-devel \
    libX11-devel \
    libXt-devel \
    initscripts \
    libXt-devel \
    gtk2-devel \
    rpm-build \
    perl-IPC-Cmd

if [ $? -eq 0 ]; then
    echo -e "\033[40;32m继续执行\033[0m" >/dev/null 2>&1
else
    echo -e "\033[1;5;41;37m\nERROR:\033[0m \033[1;40;31m服务器无法访问互联网或没有内部仓库，请配置（已知部分RHEL 8、龙蜥批量安装会有一些奇奇怪怪的问题）\n\033[0m"
    exit
fi
echo
;;

"2")
echo -e "\033[1;40;32m忽略依赖安装\033[0m"
echo
sleep 1
;;

*)
	echo -e "\033[1;5;41;37mERROR:\033[0m \033[1;40;31m输入错误，请重新执行脚本\033[0m"
	echo
	exit
;;
esac
#编译OpenSSL
function OpenSSL_Build(){
#清理
rm -rf /opt/openssl-*rpms*
mkdir -p /root/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cp openssl-3.3.1.tar.gz /root/rpmbuild/SOURCES
cd /root/rpmbuild/SPECS && \

# SPEC file
cat > openssl.spec << EOF
Summary: OpenSSL 3.3.1 for $OS
Name: openssl
Version: %{?version}%{!?version:3.3.1}
Release: 1%{?dist}
Obsoletes: %{name} <= %{version}
Provides: %{name} = %{version}
URL: https://www.openssl.org/
License: GPLv2+

Source: https://www.openssl.org/source/%{name}-%{version}.tar.gz

%define debug_package %{nil}
BuildRequires: make gcc perl
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
%global openssldir /usr/openssl

%description
https://github.com/Nugent1a/openssh-rpms
OpenSSL RPM for version 3.3.1 on $OS

%package devel
Summary: Development files for programs which will use the openssl library
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}

%description devel
OpenSSL RPM for version 3.3.1 on $OS (development package)

%package libs
Summary: Libraries for OpenSSL
Group: System Environment/Libraries
Requires: %{name} = %{version}-%{release}

%description libs
OpenSSL libraries for version 3.3.1 on $OS

%prep
%setup -q

%build
./config --prefix=%{openssldir} --openssldir=%{openssldir} enable-md2
make -j$(nproc)

%install
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}
%make_install

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib64/libssl.so.3 %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib64/libcrypto.so.3 %{buildroot}%{_libdir}
ln -sf %{openssldir}/bin/openssl %{buildroot}%{_bindir}

%clean
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}

%files
%{openssldir}
%defattr(-,root,root)
/usr/bin/openssl
/usr/lib64/libcrypto.so.3
/usr/lib64/libssl.so.3

%files devel
%{openssldir}/include/*
%defattr(-,root,root)

%files libs
%{openssldir}/lib64/*
%defattr(-,root,root)

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

EOF

rpmbuild -D "version 3.3.1" -bb openssl.spec
mkdir /opt/openssl-3.3.1-rpms
mv /root/rpmbuild/RPMS/x86_64/* /opt/openssl-3.3.1-rpms
#卸磨杀驴
rm -rf /root/rpmbuild
}

#编译OpenSSH
function OpenSSH_Build(){
#清理
rm -rf /opt/openssh-*rpms*
#OpenSSH源码包目录
OPENSSH_DIR=$(find / -name openssh-$OPENSSH_VERSION.tar.gz)
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
}

function OPTION(){
read -p "请选择

1、OpenSSL_Build
2、OpenSSH_Build

:" Upgrade_VALUE
case $Upgrade_VALUE in
"1"|"Build_OpenSSL")
OpenSSL_Build
echo -e "\033[1;40;32m\nOpenSSL编译完成\n\033[0m"
exit
;;

"2"|"OpenSSH_Build")
OpenSSH_Build
echo -e "\033[1;40;32m\nOpenSSH编译完成\n\033[0m"
exit
;;


*)
echo
echo -e "\033[1;5;41;37mERROR:\033[0m \033[1;40;31m输入错误，请重新输入\n\033[0m"
OPTION
;;

esac
}
OPTION
