#!/bin/bash

source /config_files/environment

export HOME=/home/ubuntu

_2log() {
	echo "[\^/^\^/\^/\^/^\^/^\^/] >>> ${1} <<< [\^/^\^/\^/\^/^\^/^\^/]"
}

_cd() {
	cd "$1" || exit 1
}

_wpcli() {
	_2log "Calling wp-cli with args: $*"
	~/wp-cli.phar "${@}" 2>&1
}

_wpcli_all() {
	for site in chrome firefox safari ie
	do
		_wpcli "${@}" --url="${BASE_URL}/${site}"
	done
}


ensure_mysql_permissions() {
	_2log 'Copy mysql config'
	sudo cp /config_files/mysql.cnf /etc/mysql
	_2log 'Restart mysql'
	sudo service mysql restart
	_2log 'Make sure we can read/write to mysql.sock'
	sudo usermod -a -G mysql ubuntu
	sudo usermod -a -G ubuntu mysql
	sudo chmod a+rw /var/run/mysqld/mysqld.sock
}


set_php_timezone() {
	_2log 'Set timezone for php'
	sudo sed -i 's|;date.timezone =|date.timezone = America/Los_Angeles|g' "${PHPENV_ROOT}/${PHPVER}/etc/php.ini"
}


update_and_enable_apache_vhost_config() {
	_2log 'Make sure apache can read/write in wordpress directory.'
	sudo chmod a+rw ../ubuntu

	_2log 'Put php version in vhost config file.'
	sed -i "s|<PHP_VERSION>|${PHPVER}|g" /config_files/wp-dev-site.conf

	_2log 'Copy apache config files.'
	sudo cp /config_files/wp-dev-site.conf "${WWWCONF_DIR}"

	_2log 'Enable apache vhost config'
	sudo a2ensite wp-dev-site && sudo a2enmod rewrite
}


download_and_install_wordpress() {
	_cd "${HOME}"

	_2log 'Download wp-cli and copy its config file to home directory.'
	wget "${WPCLI_URL}" && chmod +x wp-cli.phar
	cp /config_files/wp-cli.yml .

	_2log 'Download WordPress into "wordpress" directory.'
	_wpcli core download
	cp /config_files/wp-cli.yml wordpress

	_2log 'Generate wp-config.php file'
	_wpcli core config
}


create_wordpress_sites() {
	for site in chrome firefox safari ie
	do
		_wpcli site create --url="${BASE_URL}/${site}" --slug="${site}"
	done
}


create_wordpress_users() {
	for site in chrome firefox safari ie
	do
		_wpcli user create "${site}user" "${site}@wp-dev-site.com" \
		--url="${BASE_URL}/${site}" \
		--role=administrator \
		--user_pass=welovewordpress
	done
}


create_wordpress_database_tables() {
	_2log 'Create database tables'
	_wpcli core multisite-install \
		--admin_user=wpdev \
		--admin_password=welovewordpress \
		--admin_email=ci@wp-dev-site.com \
		--skip-email \
		--title='WP Dev Site'
	_wpcli option set siteurl "${BASE_URL}"
	_wpcli option set homeurl "${BASE_URL}"
}


set_permalinks_and_copy_htaccess_file() {
	_wpcli_all rewrite structure '/%postname%'
	cp config_files/.htaccess "${HOME}/wordpress/.htaccess"
}


ensure_apache_permissions() {
	_2log 'Stop mysql'
	service mysql stop

	_2log 'Restart Apache and fix file permissions'
	( _cd "${HOME}" \
		&& sudo chown -R www-data:www-data wordpress \
		&& sudo find wordpress -type f -exec chmod 644 {} \; \
		&& sudo find wordpress -type d -exec chmod 755 {} \; \
		&& sudo service apache2 restart )
}


download_browserstack_binary() {
	( _cd "${HOME}" \
		&& wget https://www.browserstack.com/browserstack-local/BrowserStackLocal-linux-x64.zip \
		&& unzip BrowserStack**.zip )
}



run_setup() {
	_cd "${HOME}"

	( ensure_mysql_permissions ) \
		&& ( set_php_timezone ) \
		&& ( update_and_enable_apache_vhost_config ) \
		&& ( download_and_install_wordpress ) \
		&& ( create_wordpress_database_tables ) \
		&& ( create_wordpress_sites ) \
		&& ( create_wordpress_users ) \
		&& ( set_permalinks_and_copy_htaccess_file ) \
		&& ( ensure_apache_permissions ) \
		&& ( download_browserstack_binary )
}


run_setup || exit 1

