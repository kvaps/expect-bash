#!/bin/bash
MOONSHOT_ID=$(echo $1 | grep -oP '(?<=^m)[0-9]+')
NODE_ID=$(echo $1 | grep -oP '(?<=c)[0-9]+$')

COMMAND="ssh -tt moonshot${MOONSHOT_ID}"
SILENT=false

pipe=`mktemp -u`
trap "rm -f $pipe" EXIT
if [[ ! -p $pipe ]]; then
    mkfifo $pipe
fi

send() {
  echo "$1" >> $pipe
}

print_by_line() {
  while IFS= read -s -r -n1 c; do
    if [ -z "$c" ]; then
      [ "$SILENT" = true ] || echo > /dev/tty
      line=""
    else
      [ "$SILENT" = true ] || echo -n "$c" > /dev/tty
      line+="$c"
    fi
    echo "$line"
  done
}

expect() {
  while read line; do
    #if [[ "$line" =~ $1 ]]; then
    if $( echo $line | grep -oPq "$1" ); then
      break
    fi
  done
}

skip() {
  cat > /dev/null
}

tail -f $pipe | $COMMAND | print_by_line | (
   expect 'hpiLO->'
   send "connect node vsp acquire c${NODE_ID}n1"
   tee \
      >( 
         expect "^.* login:"
         send "root"
         expect "Password:"
         send "hackme"
         skip
       ) \
      >( 
         expect "root@.*"
         send 'ip addr'
         send 'exit'
         skip
       ) \
       | skip
)
