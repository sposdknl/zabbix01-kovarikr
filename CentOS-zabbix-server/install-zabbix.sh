# Instalace balícku net-tools
sudo dnf update

# Stažení balíčku pro instalaci zabbix repo
sudo rpm -Uvh https://repo.zabbix.com/zabbix/7.0/centos/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm
sudo dnf clean all

# Aktualizace repository
sudo dnf install -y mariadb-server
sudo dnf install -y zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent

# Instalace Apache (httpd)
sudo dnf install -y httpd

# Povolení Apache služby
sudo systemctl enable httpd

# Povoleni sluzby zabbix-agent2
sudo systemctl enable mariadb.service
sudo systemctl enable zabbix-server zabbix-agent php-fpm

# Restart sluzby zabbix-agent2 a apache
sudo systemctl restart mariadb.service
sudo systemctl restart zabbix-server zabbix-agent httpd php-fpm

# EOF
