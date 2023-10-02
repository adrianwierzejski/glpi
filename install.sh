apt install mariadb-server
echo "CREATE DATABASE glpi;
CREATE USER 'glpi'@'localhost' IDENTIFIED BY 'StrongDBPassword';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';
FLUSH PRIVILEGES;" | sudo  mysql -u root
mysql_secure_installation
apt -y install php php-{curl,zip,bz2,gd,imagick,intl,apcu,memcache,imap,mysql,cas,ldap,tidy,pear,xmlrpc,pspell,mbstring,json,iconv,xml,gd,xsl}
apt -y install apache2 libapache2-mod-php
wget https://github.com/glpi-project/glpi/releases/download/10.0.9/glpi-10.0.9.tgz
tar zxvf glpi-10.0.9.tgz -C /var/www/glpi
mv /var/www/glpi/config /etc/glpi
mv /var/www/glpi/files /var/lib/glpi
mkdir /var/log/glpi

cat <<EOF > /var/www/glpi/inc/downstream.php
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');

if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
   require_once GLPI_CONFIG_DIR . '/local_define.php';
}
EOF

cat <<EOF > /etc/apache2/sites-available/001-glpi.conf
<VirtualHost *:80>
    ServerName localhost

    DocumentRoot /var/www/glpi/public

    # If you want to place GLPI in a subfolder of your site (e.g. your virtual host is serving multiple applications),
    # you can use an Alias directive. If you do this, the DocumentRoot directive MUST NOT target the GLPI directory itself.
    # Alias "/glpi" "/var/www/glpi/public"

    <Directory /var/www/glpi/public>
        Require all granted

        RewriteEngine On

        # Redirect all requests to GLPI router, unless file exists.
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
EOF

cat <<EOF > /etc/glpi/local_define.php
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
define('GLPI_LOG_DIR', '/var/log/glpi');
EOF
chown -R www-data:www-data /var/www/glpi
chown -R www-data:www-data /var/log/glpi
chown -R www-data:www-data /var/lib/glpi
chown -R www-data:www-data /etc/glpi

cat /etc/php/*/apache2/php.ini | sed -e "s/session.cookie_httponly =/session.cookie_httponly = On/" > /etc/php/*/apache2/php.ini.new
mv /etc/php/*/apache2/php.ini /etc/php/*/apache2/php.ini.old
mv /etc/php/*/apache2/php.ini.new /etc/php/*/apache2/php.ini

a2enmod rewrite
a2ensite 001-glpi.conf
systemctl reload apache2
