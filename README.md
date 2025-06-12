# GLPI 10.x em Docker

## Procedimentos

Criar os arquivos secrets para o banco de dados:
```
touch conf/mysql/secrets/MYSQL_DATABASE
touch conf/mysql/secrets/MYSQL_USER
touch conf/mysql/secrets/MYSQL_PASSWORD
touch conf/mysql/secrets/MYSQL_ROOT_PASSWORD
```

Copiar o arquivo modelo do banco para o GLPI e ajustar o seu conteúdo com as mesmas informações do secret: `conf/glpi/config_db.php`.

Copiar e ajustar, se necessário, os arquivos `.env` e `docker-compose.yml`.

Realizar o build da imagem e inicar os containers. Neste caso pode usar o `script.sh`. Exemplo:
```
./script.sh pull
./script.sh build
./script.sh start
./script.sh stop
./script.sh restart
./script.sh backup
./script.sh routine
./script.sh ps
./script.sh logs
```

Analisar e adicionar as rotinas conforme o necessário:
```
./script.sh schedule cron
./script.sh schedule unlock
./script.sh schedule clear
./script.sh schedule timestamps
./script.sh schedule ldapsync
```

Adicionar na rotina o logrotate do nginx
```
./script.sh logrotate
```

Instalação na primeira construção do ambiente, com o banco de dados novo:
```
docker compose exec -it --user www-data server bash -c 'php bin/console database:install --no-telemetry --no-interaction'
```