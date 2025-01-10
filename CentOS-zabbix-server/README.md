# Instalace Zabbix Agent2 na CentOS
## Zvolil jsem si automatickou instalaci Zabbixu
### Instalace Zabbix repository
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu22.04_all.deb
dpkg -i zabbix-release_latest+ubuntu22.04_all.deb
apt-get update

# Instalace MySQL serveru
apt-get install -y mysql-server

# Start MySQL služby
systemctl start mysql
systemctl enable mysql

# Vytvoření databáze pro Zabbix
mysql -u root -e "CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"

# Vytvoření uživatele a přiřazení práv
mysql -u root -e "CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED WITH mysql_native_password BY 'zabbix_password';"
mysql -u root -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Povolení log_bin_trust_function_creators
mysql -u root -e "SET GLOBAL log_bin_trust_function_creators = 1;"

# Import databázového schématu Zabbix
if [ -f /usr/share/zabbix-sql-scripts/mysql/server.sql.gz ]; then
    zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u zabbix -p'zabbix_password' zabbix
else
    echo "Zabbix databázový skript nebyl nalezen."
    exit 1
fi

# Zakazuji log_bin_trust_function_creators
mysql -u root -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# Konfigurace Zabbix serveru
sed -i 's/# DBPassword=/DBPassword=zabbix_password/' /etc/zabbix/zabbix_server.conf

# Restart Zabbix serveru a agentu
systemctl restart zabbix-server zabbix-agent2 apache2
systemctl enable zabbix-server zabbix-agent2 apache2

# Konfigurace PHP pro Zabbix frontend
PHP_INI_PATH=$(php --ini | grep "/cli/php.ini" | sed 's|/cli/php.ini||')
if [ -n "$PHP_INI_PATH" ]; then
    sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$PHP_INI_PATH/apache2/php.ini"
    sed -i 's/^memory_limit = .*/memory_limit = 128M/' "$PHP_INI_PATH/apache2/php.ini"
    sed -i 's/^post_max_size = .*/post_max_size = 16M/' "$PHP_INI_PATH/apache2/php.ini"
    sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 2M/' "$PHP_INI_PATH/apache2/php.ini"
    sed -i 's/^;date.timezone =.*/date.timezone = Europe\/Prague/' "$PHP_INI_PATH/apache2/php.ini"
else
    echo "Nelze najít php.ini pro Apache."
    exit 1
fi

# Restart Apache
systemctl restart apache2

# Konfigurace Zabbix agenta
sed -i "s/Hostname=Zabbix server/Hostname=localhost/g" /etc/zabbix/zabbix_agent2.conf
sed -i 's/Server=127.0.0.1/Server=enceladus.pfsense.cz/g' /etc/zabbix/zabbix_agent2.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive=enceladus.pfsense.cz/g' /etc/zabbix/zabbix_agent2.conf

# Restart Zabbix agenta
systemctl restart zabbix-agent2

# Závěr
Po provedení těchto kroků bude Zabbix server plně nainstalován a nakonfigurován s databází a frontendem připraveným pro připojení. Zabbix agent bude také nakonfigurován a připraven k monitorování systémů.

# Shrnutí:
Instalace Zabbix serveru a agenta.
Instalace a konfigurace MySQL.
Vytvoření databáze a uživatele pro Zabbix.
Import databázového schématu a nastavení Zabbix serveru.
Konfigurace PHP pro frontend.
Restartování potřebných služeb (Zabbix server, agent, Apache)