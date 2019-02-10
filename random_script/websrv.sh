#!/bin/bash
# echo -e -n "HTTP 200 OK \r\nContent-Length:0\r\nHost: $(hostname)\r\n\r\n" | netcat -l -p 9999
# echo -e -n "$(hostname)\r\n" | netcat -l -p 9999

myport="${useport:-9999}"
while true
do
    echo -e -n "HTTP 200 OK \r\nContent-Length:0\r\nHost: $(hostname)\r\n\r\n" | netcat -l -p "${myport}"
done

