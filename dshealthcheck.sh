[root@yac-vl-00258 ~]# cat /etc/dshealthcheck/dshealthcheck.sh
#!/usr/bin/bash

# Настройка переменных
LOG_DIR="/var/log/dshealthcheck"
LOG_FILE="$LOG_DIR/dshealthcheck.log"


# Проверить, существует ли каталог с логами
if [ ! -d "$LOG_DIR" ]; then
# Создать каталог с логами
mkdir -p "$LOG_DIR"
fi


# Функция для записи лога
function log() {
  # Получить текущую дату и время
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")

  # Записать лог в файл
  echo "$timestamp $1 - $2" >> "$LOG_FILE"
}

# Получаем запрос от клиента и читаем содержиое запроса из переменных окружения:
read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION
log "INFO" "Recieved request - Method:$REQUEST_METHOD URI:$REQUEST_URI Client_ip:$SOCAT_PEERADDR"


# Проверяем, что запрошенный метод поддерживается и конечная точка подлежит обработке
if [ "$REQUEST_METHOD" == "GET" ]; then
  if [ "$REQUEST_URI" == "/dshealthcheck" ]; then
    #Проверяем что ответ LDAP result: * Success
    log "INFO" "Run LDAPSearch"

    response=$(ldapsearch -H ldaps://localhost:636 -D "uid=reader,ou=sub,dc=mars,dc=ext" -w 'GPy3BpKJtm' -b "dc=mars,dc=ext" mail=wrongmail)

    [[ $response =~ .*result:.*Success.* ]] && code=200 || code=503
    log "INFO" "LDAPSearch result - $response"
    if [[ $code == 200 ]]; then
      log "INFO" "Response to client - 200 OK"
      echo -e "HTTP/1.1 200 OK\nContent-Type: text/plain\n\n"
    else
      log "ERROR" "BAD LDAPSearch response"
      log "WARNING" "Response to client - 503 Service Unavailable"
      echo -e "HTTP/1.1 503 Service Unavailable\nContent-Type: text/plain\n\n"
    fi
  else
    log "INFO" "Response to client - 404 Not Found"
    echo -e "HTTP/1.1 404 Not Found\nContent-Type: text/plain\n\n"
  fi
else
  log "INFO" "Response to client - 405 Method Not Allowed"
  echo -e "HTTP/1.1 405 Method Not Allowed\nContent-Type: text/plain\n\n"
fi

