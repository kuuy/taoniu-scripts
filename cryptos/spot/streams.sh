#/bin/sh

SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

CONFIG=$(cat <<-END
[program:binance-spot-streams-#ID]

command=/root/taoniu-go/cryptos binance spot streams #ID
numprocs=1
startsecs=3
startretries = 1
exitcodes=0
stopwaitsecs=5
autostart=true
autorestart=true

stdout_logfile_maxbytes=0\n
stderr_logfile_maxbytes=0\n
END
)

count=$( redis-cli -n 8 HGET "binance:symbols:count" "spot" )
count=$((count+0))
max=$((count/30))
if [ $((max*30)) -lt $count ]; then
  max=$((max+1))
fi

find /etc/supervisor.d -name "binance-spot-streams-*.conf" -exec basename {} \; | while read file; do
  id=$(echo $file | sed -e "s/binance-spot-streams-//g" -e "s/.conf//g" | awk '{print toupper($0)}')
  id=$((id+0))
  if [ $id -gt $max ]; then
    FILE=/etc/supervisor.d/binance-spot-streams-$id.conf
    rm -f $FILE
  fi
done

id=1
while [ $count -gt 0 ]; do
  config=$(echo "$CONFIG" | sed -e "s/#ID/${id}/g")
  FILE=/etc/supervisor.d/binance-spot-streams-$id.conf
  if [ ! -f "$FILE" ]; then
    echo "$config" > $FILE
  fi
  count=$((count-30))
  id=$((id+1))
done

supervisord ctl reload
