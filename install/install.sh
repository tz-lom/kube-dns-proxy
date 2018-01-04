#!/bin/sh

if [ -z "$(iptables -t nat -L PREROUTING | grep $KUBE_DNS_SERVER)" ]; then
    iptables -t nat -I PREROUTING --dest $KUBE_DNS_SERVER -p udp --dport 53 -j DNAT --to-dest 127.0.0.1
fi
