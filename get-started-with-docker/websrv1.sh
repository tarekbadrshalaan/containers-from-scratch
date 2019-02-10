#!/bin/bash
# echo -e -n "HTTP 200 OK \r\nContent-Length: 0\r\nHost: $(hostname)\r\n" | netcat -l -p 9000

# while true
# do
#     echo -e -n "HTTP 200 OK \r\nContent-Length: 0\r\nHost: $(hostname)\r\n" | netcat -l -p 9000
# done

myport="${USE_PORT:-9000}"
while true
do
    echo -e -n "HTTP 200 OK \r\nContent-Length: 0\r\nHost: $(hostname)\r\n" | netcat -l -p "${myport}"
done
