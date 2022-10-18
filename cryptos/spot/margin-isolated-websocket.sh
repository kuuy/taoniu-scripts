#/bin/sh

SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

CONFIG=$(cat <<-END
[program:binance-spot-margin-isolated-websocket-#symbol]

command=/root/taoniu-go/cryptos binance spot margin isolated websocket #SYMBOL
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

find /etc/supervisor.d -name "binance-spot-margin-isolated-websocket-*.conf" -exec basename {} \; | while read file; do
  symbol=$(echo $file | sed -e "s/binance-spot-margin-isolated-websocket-//g" -e "s/.conf//g" | awk '{print toupper($0)}')
  exists=$( redis-cli -n 8 SISMEMBER "binance:spot:margin:isolated:symbols" $symbol )
  if [ "$exists" = "0" ]; then
   symbol=$(echo "$symbol" | awk '{print tolower($0)}')
   FILE=/etc/supervisor.d/binance-spot-margin-isolated-websocket-$symbol.conf
   rm -f $FILE
  fi
done

redis-cli -n 8 SMEMBERS "binance:spot:margin:isolated:symbols" | while read SYMBOL && [ ! -z "$SYMBOL" ]; do
  symbol=$(echo "$SYMBOL" | awk '{print tolower($0)}')
  config=$(echo "$CONFIG" | sed -e "s/#symbol/${symbol}/g" -e "s/#SYMBOL/${SYMBOL}/g")
  FILE=/etc/supervisor.d/binance-spot-margin-isolated-websocket-$symbol.conf
  if [ ! -f "$FILE" ]; then
    echo "$config" > $FILE
  fi
done

supervisord ctl reload
