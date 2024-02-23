#!/bin/bash


LONG=(action:, help)
SHORT=(a:,h)
OPTS=$(/usr/bin/getopt --name vpnManager --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"


function stopVpn() {
    while read -r line;
    do
    sudo kill -SIGTERM $line
    done < <(/usr/bin/pgrep openvpn)
    pids=$(pgrep openvpn)
    if [ -z $pids ]
    then
    echo "Successfully killed openvpn"
    fi
}

function findVpn() {
    echo "searching for ovpn file ..."
    VPN=$(/usr/bin/find / -type f -name "*.ovpn" 2>/dev/null)
    echo "using $VPN as HTB vpn"
    if [ -z $VPN ]
    then
        echo "no ovpn file found ... :c"
        exit 1
    fi
}

function help() {
    echo "Syntax: vpnManager [-a/--action] <start, stop, info> [-s/--server] <region-n>"
    echo
    echo "--action, -a start, stop, get info about vpn, example: --action start"
    echo "--help, -h, show this help, btw, the --help does not work for some reason, so use -h"
    echo
}

if [ $# -eq 1 ]; then
    help
    exit 1
fi

while :
do
  case "$1" in
    '' )
      help
      exit 2
      ;;
    -a | --action )
      action="$2"
      shift 2
      ;;
    -h | --help )
      help
      exit 2
      ;;
    --)
      shift;
      break
      ;;
  esac
done

case "$action" in
  start )
  if [ ! -z "$(pgrep openvpn)" ]
  then
    stopVpn
  fi
  if [ -z $VPN ] 
    then
    findVpn
  fi

  if [ ! -d /tmp/vpnManager ]; then
    mkdir /tmp/vpnManager
  fi
  log_file=/tmp/vpnManager/openvpn.log
  sudo /usr/sbin/openvpn --config $VPN --log "$log_file" --daemon --mute-replay-warnings | grep -v "WARNING"
  sudo chmod +r "$log_file"
  ;;
  stop )
  stopVpn
  exit 0
  ;;
esac

start=$(date +%s)
while [ $(($(date +%s) - $start)) -lt 10 ]
do
output=$(/usr/bin/cat -s "$log_file")
check="Initialization Sequence Completed"
if [[ "$output" == *"$check"* ]]
then
    echo "Successfully started VPN !"
    sudo rm "$log_file"
    exit 0
fi
done
echo "couldn't start openvpn with $VPN, you might want to change it or check the logs at $log_file"