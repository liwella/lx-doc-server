#!/bin/bash

# 后台模式启动 nginx，并指定nginx配置文件路径，如果使用了 docekr 部署，这个配置文件请映射到宿主机
# 以便随时修改，每次修改之后可通过 docker exec -it 【容器id】 nginx -s reload -c /usr/nginx/config/nginx.conf
# 重启 nginx
nginx -g "daemon on;" -c /usr/nginx/config/nginx.conf

SERVICE=$(cd $(dirname $0); pwd | awk -F '/' '{print $(NF)}')
MEMORY=512m

# 启动mysql
nohup /bin/sh /usr/app/${SERVICE}/mysql_init_start.sh &

MYSQL_PORT=${MYSQL_PORT:-"3306"}
while true; do
  if netstat -tuln | grep -q ":$MYSQL_PORT"; then
      echo "MySQL is currently running..."
      break
  else
      echo "wait mysql start..."
      sleep 1
  fi
done

Start() {
    mem=$1
    echo ${mem}
    if [ -z "$mem" ];then
        mem=$MEMORY
    fi

    proc=$(ps -ef | grep /usr/app/${SERVICE}/${SERVICE}.jar | grep -v grep | wc -l)
    if [[ $proc != 0  ]];then
        exit 5
    fi

    java -server -Xms${mem} -Xmx${mem}  -jar /usr/app/${SERVICE}/${SERVICE}.jar  $ARGS
}


Stop() {
    /usr/bin/ps -ef | grep ${SERVICE} | grep -v grep | awk '{print $2}'| xargs kill -9
}

Restart() {
    Stop
    Start
}


case $1 in
    start|run)
        Start $2
        ;;
    stop)
        Stop
        ;;
    restart)
        Restart
        ;;
esac
