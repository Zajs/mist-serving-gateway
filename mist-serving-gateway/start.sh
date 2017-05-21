#!/bin/sh

[ -z "$NETWORK_SUBNET" ] && NETWORK_SUBNET='0.0.0.0'

HOST_NODE_IP=$(netstat -nr | grep "^0\.0\.0\.0" | awk '{print $2}')
HOST_ETH=$(netstat -nr | grep "^0\.0\.0\.0" | awk '{print $8}')
HOST_CONTAINER_IP=$(ifconfig $HOST_ETH | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

NODE_ETH=$(netstat -nr | grep "^$NETWORK_SUBNET" | awk '{print $8}')
CONTAINER_IP=$(ifconfig $NODE_ETH | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
CONTAINER_ID=$(cat /proc/self/cgroup | grep docker | grep -o -E '[0-9a-f]{64}' | head -n 1)

[ -z "$APPLICATION_NAME" ] && APPLICATION_NAME='mist-serving-gateway'
[ -z "$CONSUL_IP" ] && CONSUL_IP=$HOST_NODE_IP
[ -z "$CONSUL_PORT" ] && CONSUL_PORT=8500

[ -z "$CONSUL_EXPOSE_IP" ] && CONSUL_EXPOSE_IP=$CONTAINER_IP
[ -z "$CONSUL_EXPOSE_PORT" ] && CONSUL_EXPOSE_PORT=80
[ -z "$CONSUL_HEALTHCHECK_IP" ] && CONSUL_HEALTHCHECK_IP=$HOST_CONTAINER_IP
[ -z "$CONSUL_HEALTHCHECK_PORT" ] && CONSUL_HEALTHCHECK_PORT=80
[ -z "$CONSUL_APPLICATION_ID" ] && CONSUL_APPLICATION_ID="docker_$CONTAINER_ID"

sed -i -- "s/APPLICATION_NAME/$APPLICATION_NAME/g" /app/consul.json
sed -i -- "s/CONSUL_EXPOSE_IP/$CONSUL_EXPOSE_IP/g" /app/consul.json
sed -i -- "s/CONSUL_EXPOSE_PORT/$CONSUL_EXPOSE_PORT/g" /app/consul.json
sed -i -- "s/CONSUL_HEALTHCHECK_IP/$CONSUL_HEALTHCHECK_IP/g" /app/consul.json
sed -i -- "s/CONSUL_HEALTHCHECK_PORT/$CONSUL_HEALTHCHECK_PORT/g" /app/consul.json
sed -i -- "s/CONSUL_APPLICATION_ID/$CONSUL_APPLICATION_ID/g" /app/consul.json

sed -i -- "s/CONSUL_HEALTHCHECK_PORT/$CONSUL_HEALTHCHECK_PORT/g" /etc/nginx/conf.d/default.conf

term_handler() {
  echo 'Stopping App....'
  if [ $APP_PID -ne 0 ]; then
    kill -s TERM "$APP_PID"
    wait "$APP_PID"
    curl --retry 3 http://$CONSUL_IP:$CONSUL_PORT/v1/agent/service/deregister/$CONSUL_APPLICATION_ID
  fi
  echo 'App stopped.'
  exit
}


# Capture kill requests to stop properly
trap "term_handler" SIGHUP SIGINT SIGTERM
ls -l /usr/local/bin
nginx
/usr/local/bin/consul-template -consul=$CONSUL_IP:$CONSUL_PORT -template="$TEMPLATE_FILE_NAME:$TEMPLATE_OUTPUT_NAME:nginx -s reload" &
APP_PID=$!

#wait server start
while ! nc -z localhost $CONSUL_HEALTHCHECK_PORT; do
  sleep 0.1 # wait for 1/10 of the second before check again
done
cat /app/consul.json
curl --max-time 10 --retry 3 --retry-delay 5 --retry-max-time 32 -v -X PUT --data @/app/consul.json http://$CONSUL_IP:$CONSUL_PORT/v1/agent/service/register

wait