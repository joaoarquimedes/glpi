#!/usr/bin/env bash

function timeStamp() { date +"%Y/%m/%d - %H:%M:%S"; }
export PATH_FULL=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $PATH_FULL

export $(cat .env)

function start(){
  if ${DOCKER_SWARM} = true
  then
    docker stack deploy --compose-file docker-compose.yml ${STACK} --detach=true
  else
    docker compose up -d
  fi
}

function stop(){
  if ${DOCKER_SWARM} = true
  then
    docker stack rm ${STACK}
  else
    docker compose down
  fi
}

function restart(){
  stop
  echo -n "Restarting."
  while ps | grep "Running" > /dev/null 2> /dev/null
  do
   echo -n "."
   sleep 2
  done
  start
  docker container prune -f
}

function reload() {
  if ${DOCKER_SWARM} = true
  then
    docker service update --force ${STACK}_server
  else
    docker compose restart
  fi
  docker container prune -f
}

function ps(){
  if ${DOCKER_SWARM} = true
  then
    docker stack ps ${STACK}
  else
    docker compose ps
  fi
}

function logs(){
  if ${DOCKER_SWARM} = true
  then
    docker service logs $(docker stack ps traefik --quiet)
  else
    docker compose logs -f
  fi
}

function build() {
  docker compose build --build-arg CACHEBUST=$(date +%s) server
}

function bash(){
  docker run --rm -it \
  --name ${STACK}-bash \
  --network ${NETWORK} \
  --env-file .env \
  --volume ./volumes/glpi/config:/var/www/html/config \
  --volume ./volumes/glpi/files:/var/www/html/files \
  --volume ./conf/glpi/config_db.php:/var/www/html/config/config_db.php \
  local/${STACK}:${GLPI_VERSION} bash
}

function test(){
  docker compose run --rm server bash -c "nginx -t"
}

function logrotate(){
  docker compose --file docker-compose.logrotate.yml run --rm logrotate ash -c 'logrotate --force --verbose /etc/logrotate.d/nginx'
}

function schedule(){
  NAME=$1
  function runSchedule(){
    docker run --rm \
    --name ${STACK}-schedule-${NAME} \
    --network ${NETWORK} \
    --env-file .env \
    --volume ./volumes/glpi/config:/var/www/html/config \
    --volume ./volumes/glpi/files:/var/www/html/files \
    --volume ./conf/glpi/config_db.php:/var/www/html/config/config_db.php \
    local/${STACK}:${GLPI_VERSION} bash -c "$COMMAND"
  }

  # Dica de rotinas:
  # cron -> A cada 1 minuto
  # unlock -> A cada 30 minutos
  # clear -> Uma vez ao dia (22:59)
  # timestamps -> Uma vez ao dia (23:59)
  # ldapsync -> A cada 1 hora. Base muito grande, a cada 2 horas
  case "$1" in
    cron)
      echo "Executando CRON"
      COMMAND="php front/cron.php"
      runSchedule
      ;;
    unlock)
      echo "Executando unlock"
      COMMAND="php bin/console glpi:task:unlock --all"
      runSchedule
      ;;
    clear)
      echo "Executando clear"
      COMMAND="php bin/console cache:clear --no-interaction"
      runSchedule
      ;;
    timestamps)
      echo "Executando timestamps"
      COMMAND="php bin/console  glpi:migration:timestamps -n"
      runSchedule
      ;;
    ldapsync)
      echo "Executando ldapsync"
      COMMAND="php bin/console ldap:synchronize_users --no-interaction"
      runSchedule
      ;;
    *)
      echo "Parâmetro inválido. Use: schedule {cron|unlock|clear|timestamps|ldapsync}"
      exit 1
      ;;
  esac
}

function backup(){
  docker run --rm \
  --name ${STACK}-backup \
  --network ${NETWORK} \
  --env-file .env \
  --volume ./conf/mysql/secrets:/secrets \
  --volume ./volumes/backups/database/:/var/backups/database \
  ${DATABASE_VERSION} bash -c '\
    mysqldump \
    --user=root \
    --password=$(cat /secrets/MYSQL_ROOT_PASSWORD) \
    --host=database $(cat /secrets/MYSQL_DATABASE) | gzip -f > /var/backups/database/$(cat /secrets/MYSQL_DATABASE)-${GLPI_VERSION}-$(date +"%a").sql.gz'
}

$@