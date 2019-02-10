# Get started with `Docker`

- Docker is technology used for create isolated environment called `Container`
- Docker  isn't the only technology for containerized there is `lxd`, `lxc` and `intel clear container` ... 


## so let's get started

* list all process in linux
```
ps -aux
```

* Install ubuntu image 
```
docker run -it ubuntu bash 
```
after running new ubuntu container 
you will find promote like this 
```
root@c783595b425b:/#
```
* create new file with message hello
```
root@25cf45c6a50b:/# echo "hello" >> /tmp/message

root@25cf45c6a50b:/# ls /tmp/
message

```

* you can't see the file from host namespaces, 
```
host@host:$ ls /tmp/message
ls: cannot access '/tmp/message': No such file or directory
```

that's because container is running into deferent namespace.
but we can share between container and host. as any allowed share between two different processes.

    * network
    * file
    * memory share 

* to share file between container and host.
```
docker run -it --volume $(pwd):/mnt/dir ubuntu bash 
```

* in the container we can run process which the host can access.

```
docker run -it ubuntu bash 

for idx in {1..10}; do echo "sleeping" | sleep 5; done &
```
you will find the process still running in the container and can't accessed from Host.
```
ps -aux | grep bash
```



## nginx server
```
docker run -d nginx
```

* from host
```
docker ps 
ps -aux | grep nginx 
```
* tree of process.
```
pstree 
```
you will find the sub process in dockerd

and this sub process running in namespace of docker 

* to run the container with port
```
docker run -d -p 9000:80 nginx 
```
* now we can from host call nginx service 
curl http://localhost:9000


## Create Webserver
```
> touch websrv1.sh

> vi websrv1.sh

#!bin/bash
echo -e -n "HTTP 200 OK \r\nContent-Length:0\r\nHost: $(hostname)\r\n\r\n" | netcat -l -p 9999

> curl http://localhost:9999
```

## Dockerfile

```
FROM debian

RUN apt-get update && apt-get install bash netcat

COPY ./websrv.sh /mnt/

CMD ["/mnt/websrv.sh"]
```

* build image 
```
docker build -t myserver:v0.0.1 .
```
* run new container 
```
docker run -d -p 5000:9999 myserver:v0.0.1 
docker run -it -p 5000:9000 myserver:v0.0.1
```
* call from host
```
curl http://localhost:5000
```
* run containr with hostname 
```
docker run -it -p 5000:9000 --hostname=worldwideweb myserver:v0.0.1 
```
* call from host
```
curl http://localhost:5000
```
* edit websrv, make it work forever.
```    
    while true
    do
        echo -e -n "HTTP 200 OK \r\nContent-Length:0\r\nHost: $(hostname)\r\n\r\n" | netcat -l -p 9999
    done
```

* build image with different version  
```
docker build -t myserver:v0.0.2 .
```
* run containr with hostname 
```
docker run -d -p 5000:9000 --hostname=worldwideweb myserver:v0.0.1 
```
* call from host
```
curl http://localhost:5000
```
* edit websrv, to get dynamic port.
```    
    myport="${useport:-9999}"
    while true
    do
        echo -e -n "HTTP 200 OK \r\nContent-Length:0\r\nHost: $(hostname)\r\n\r\n" | netcat -l -p "${myport}"
    done
```

* build image with different version  
```
docker build -t myserver:v0.0.3 .
```
* run containr with hostname and port
```
docker run -d -p 5000:9000 -e USE_PORT=9000 --hostname=worldwideweb myserver:v0.0.3 
```

## Docker Hub
### docker login 

* docker tag image
docker tag myserver:v0.0.3 tarekbadr/myserver:latest

* docker push image 
docker push tarekbadr/myserver


* pull images online and run 
docker run -d -p 5000:9999 -e USE_PORT=9999 tarekbadr/myserver:latest

* call from host
```
curl http://localhost:9999
```





