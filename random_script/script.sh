# list all process in linx 
ps -aux 

# install ubuntu image 
docker run -it ubuntu bash 

ps -aux 

# view change from in the container of the out side 
#from host 
echo "course" >> /tmp/message

ls -la /tmp

#from container 
ls -la /tmp

### contaier run into namespace.

### this is mount namespace.

# processec only can talk to each other 
    1. network
    2. file 
    3. memory share

# share file between processes 
docker run -it --volume $(pwd) :/mnt/dir ubuntu bash 

# from host 
    vi file
        add message

# from containr 
    ls # you will find the file 
    cat file 

###

# from host 

for idx in {1..10}; do echo "sleeping" | sleep 5; done &
for idx in {1..10}; do sleep 5; done &

ps -aux | grep bash # you will find the process still running 


kill PID

# the id is not exist in the contianr 
# and you can't communicat with process you don't know it's ID .

###

# nginx server
docker run -d nginx

# from host
docker ps 
ps -aux | grep nginx 

pstree # tree of process.
# you will find the sub process in dockerd
# and this sub process running in namespace of docker 

# to run with port 
docker run -d -p 9000:80 nginx 

# from host 
curl http://localhost:9000


# run mutilple containr
docker run -d nginx
docker run -d nginx
docker run -d nginx
docker run -d nginx

# view process tree
pstree # you will find 5 process running in contaires

###

# create webserver :30:03
touch websrv.sh
vi websrv.sh
    #!bin/bash
    echo -e -n "HTTP 200 OK \r\nContent-Length:0\r\nHost: $(hostname)\r\n\r\n" | netcat -l -p 9999

curl http://localhost:9999
curl -vv http://localhost:9999



# start Dockerfile
FROM debian

RUN apt-get update && apt-get install bash netcat

COPY ./websrv.sh /mnt/

CMD ["/mnt/websrv.sh"]

# build image 
docker build -t myserver:v0.0.1 .

# run containr 
docker run -d -p 5000:9999 myserver:v0.0.1 

# from host 
curl -vv http://localhost:9999

# run containr with hostname 
docker run -d -p 5000:9999 --hostname=worldwideweb myserver:v0.0.1 

# from host 
curl -vv http://localhost:9999


# watch docker process 
docker ps

###

# edit websrv
while true
do
    echo -e -n "HTTP 200 OK \r\nContent-Length:0\r\nHost: $(hostname)\r\n\r\n" | netcat -l -p 9999
done


# edit websrv 
myport="${useport:-9999}"
while true
do
    echo -e -n "HTTP 200 OK \r\nContent-Length:0\r\nHost: $(hostname)\r\n\r\n" | netcat -l -p "${myport}"
done

# build image 
docker build -t myserver:v0.0.2 .

# run containr 
docker run -d -p 5000:9999 -e useport=5000 myserver:v0.0.2 

# docker login 
# docker upload image

docker tag myserver:v0.0.2 tarekbadr/myserver:latest

docker push tarekbadr/myserver 

# pull images online 
docker run -d -p 5000:9999 -e useport=5000 tarekbadr/myserver:latest

curl http://localhost:5000

####
####1:09:30

# how container works

# there is two important features in linux 
# 1. namespace : this about what you will see , what is your availble space: 
#   network,directories,hostname , etc. 
# 2. cgroups : to controle the resources giving to your process : cpu , memory ,io read_write, etc. 
#   like you are allow only 10000 io/sec.

sudo -s # run shell as the target user; a command may also be specified

echo $USER # : root 

unshare # to get into namespace

unshare --help # to get help for unshare

unshare --fork --pid --mount-proc /bin/bash 

unshare --fork --mount --uts --net --pid --user --map-root-user /bin/bash


# add uts to change hostname 
unshare --fork --pid --uts --mount-proc /bin/bash 

# add mount to mount the machine 
unshare --fork --pid --uts --mount --mount-proc /bin/bash

###
mkdir /tmp/ict

# etc is contain all configuration for the machine.
mount --bind /tmp/ict/ /etc/

ls /etc

echo "print('hello-world')" >> app.py

python app.py


# you can find more with search for "clone syscall"
# http://man7.org/linux/man-pages/man2/clone.2.html


###
### network namespace
### we need to create to network to communcate between each other.
### to create network namespace you can't use unshare, you have to use 'ip netns'
# https://ops.tips/blog/using-network-namespaces-and-bridge-to-isolate-servers/
# https://www.youtube.com/watch?v=vC6YpqUWO0Q


sudo -s # to work as root 

ip netns add ns01 # network one 
ip netns add ns02 # network two

ip netns list # to list network namespaces in your system.

##
# start create a link to share on it (ns01)
ip link add ns01master type veth peer name ns01slave

# to show ip network
ip addr show # you will find ns01master@ns01slave,ns01slave@ns01master

# to link the first link with the first network
ip link set ns01slave netns ns01 name eth0

ip addr show # you will find only ns01master@ns01slave

ip netns exec ns01 ip addr show # execute "ip addr show" in "ns01"


##
# start create a link to share on it (ns02)
ip link add ns02master type veth peer name ns02slave

# to show ip network
ip addr show # you will find ns01master@ns01slave,ns01slave@ns01master

# to link the first link with the first network
ip link set ns02slave netns ns02 name eth0

ip addr show # you will find only ns01master@ns01slave

ip netns exec ns02 ip addr show # execute "ip addr show" in "ns01"

##
# start create bridge 

brctl show # to list all bridge in the system 

brctl addbr b0 # add bridge one 

brctl show # you will find 'b0' wihtout any interface

brctl addif b0 ns01master # add master link 1 to bridge 
brctl addif b0 ns02master # add master link 2 to bridge 


##
# start assign ip for diveces in namespaces

ip netns exec ns01 ip addr add 11.0.0.4/16 dev eth0
ip netns exec ns02 ip addr add 11.0.0.5/16 dev eth0

##
# start run the network
ip link set dev b0 up # start up bridge

ip netns exec ns01 ip link set dev eth0 up # start run device one in namespce one.
ip netns exec ns02 ip link set dev eth0 up # start run device one in namespce two.

ip netns exec ns01 ip link set dev lo up # start up loop back device
ip netns exec ns02 ip link set dev lo up # start up loop back device

ip netns exec ns01 ping 11.0.0.4 # ns01 ping it self 
ip netns exec ns02 ping 11.0.0.5 # ns02 ping it self 

ip link set dev ns01master up # up the master side for network one.
ip link set dev ns02master up # up the master side for network two.



# view bridge stats 
brctl showstp b0


