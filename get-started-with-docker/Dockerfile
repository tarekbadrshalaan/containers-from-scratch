FROM debian

RUN apt-get update && apt-get install bash netcat

COPY ./websrv1.sh /mnt/

CMD ["/mnt/websrv1.sh"]