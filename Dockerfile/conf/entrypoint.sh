#!/bin/bash

function prepare() {
  echo "--> Prepare"

  # Creating sub-directories in the files folder
  base_path="${GLPI_DIR}/files"
  directories="
    _cache
    _cron
    _dumps
    _graphs
    _lock
    _log
    _pictures
    _plugins
    _rss
    _sessions
    _tmp
    _uploads
  "

  echo "--> Especificando permissão na pasta: $base_path"
  chown www-data:www-data $base_path

  for dir in $directories; do
    full_path="$base_path/$dir"
    if [ ! -d "$full_path" ]
    then
      echo "-> Criando diretório: $full_path"
      mkdir -p "$full_path"
      chown www-data:www-data $full_path
      chmod 775 $full_path
    else
      echo "-> Ajustando permissoes: $full_path"
      chown -R www-data:www-data $full_path
    fi
  done

  # Check config volume content
  echo "-> Verificando conteúdo das configurações"
  rsync -avzog /usr/src/glpi/config/ ${GLPI_CONFIG_DIR}/
  chown -R www-data: ${GLPI_CONFIG_DIR}
  chown www-data: ${GLPI_DIR}/marketplace
  chown www-data: ${GLPI_DIR}/plugins
}

# Run command
if [ "$1" = "start" ]
then
  prepare &
  echo "--> Start php-fpm"
  mkdir -p /run/php/ && chown www-data: /run/php/
  php-fpm -t && php-fpm --daemonize
  if [ $? -eq 0 ]
  then
    echo "--> Start nginx"
    nginx -t && nginx -g 'daemon off;' || { echo "Erro ao iniciar o nginx"; exit 1 ;}
  else
    echo "Erro ao iniciar o php-fpm"
    exit 1
  fi
else
  exec "$@"
fi
