#!/bin/bash

export HOME=/home/ubuntu

source "${HOME}/runtime_environment/environment"

_2log() {
	echo "[\^/^\^/\^/\^/^\^/^\^/] >>> ${1} <<< [\^/^\^/\^/\^/^\^/^\^/]"
}

_cd() {
	cd "$1" || exit 1
}


create_symlink_to_source_repo() {
	ln
}




run() {
	_cd "${HOME}"

	ln -sr source_repo "${REPO}"
	
	

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

