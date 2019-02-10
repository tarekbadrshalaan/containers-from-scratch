# How Containers work

there is two important features in linux 
 1. namespace : this about what you will see , what is your available space: 
   network,directories,hostname , etc. 
 2. C-Groups : to controls the resources giving to your process : cpu , memory ,io read_write, etc. 
   like you are allow only 10000 io/sec.

## So let's get started

## first let's work with `unshare` command

* run shell as the target root user
```
sudo -s
```

* we use command `unshare` to work with namespace, and the options available
are about what you will allow to use.
```
> unshare --uts         # give you ability to change hostname  
> unshare --mount       # give you ability to mount volumes   
> unshare --mount-proc  # give you ability to start new tree process
... 
> unshare --help
```
here you can find more about `clone syscall` : http://man7.org/linux/man-pages/man2/clone.2.html

* to fork namespace without new process tree
```
unshare --fork --mount --uts --net --pid --user --map-root-user
```

* view pstree in new namespace
```
pstree
```

* start mount empty tmp file to `etc`
`etc is contain all configuration for the machine`
```
mount --bind /tmp/ict/ /etc/

ls /etc

echo "print('hello-world')" >> app.py

python app.py
```



* start new namespace with deferent process mount
```
unshare --fork --pid --mount-proc /bin/bash
```

* run long process 
```
for idx in {1..10};do echo "test" | sleep 5; done &
```

* view pstree in new namespace
```
pstree
```

## so let's create our network namespace
### we need to create to two networks to communicate between each other.
### to create network namespace you can't use unshare, you have to use 'ip netns'
ref.

https://ops.tips/blog/using-network-namespaces-and-bridge-to-isolate-servers/

https://www.youtube.com/watch?v=vC6YpqUWO0Q

https://serverfault.com/questions/568839/linux-network-namespaces-ping-fails-on-specific-veth

https://unix.stackexchange.com/questions/405805/connecting-two-network-namespaces-via-a-veth-interface-pair-where-each-endpoint

http://fosshelp.blogspot.com/2014/08/connect-two-network-namespaces-using.html



### create two network namespaces / over BRIDGE
```
ip netns add ns01
ip netns add ns02
```

* show list of network namespaces
```
ip netns list
```

### start create a links to share it on namespaces
```
ip link add ns01master type veth peer name ns01slave
ip link add ns02master type veth peer name ns02slave
```

* list ip address
```
ip addr show
```

* connect links to namespaces 
```
ip link set ns01slave netns ns01 name eth0
ip link set ns02slave netns ns01 name eth0
```

* list ip address, and find the changes 
```
ip addr show
```

* list ip address inside namespaces 
```
ip netns exec ns01 ip addr show 
ip netns exec ns02 ip addr show
```

### start creating bridge, and list them
```
brctr add br1
brctr show 
```

* add links as interface to bridge 
```
brctl addif br ns01master
brctl addif br ns02master
```

* start assign ip for devices in namespaces
```
ip netns exec ns01 ip addr add 11.0.0.4/16 dev eth0
ip netns exec ns02 ip addr add 11.0.0.5/16 dev eth0
```

### start the network 

* start up bridge 
```
ip link set dev br1 up 
```

* start up device in namespaces 
```
ip netns exec ns01 ip link set dev eth0 up
ip netns exec ns02 ip link set dev eth0 up
```

* start up loop back in namespaces 
```
ip netns exec ns01 ip link set dev lo up
ip netns exec ns02 ip link set dev lo up
```

* start up link masters 
```
ip link set dev ns01master up
ip link set dev ns02master up
```

* view bridge status 
```
brctr showstp br1
```


### create two network namespaces / over LINKS
```
ip netns add ns01
ip netns add ns02
```

* show list of network namespaces
```
ip netns list
```

* Create a veth virtual-interface pair to communicate over it. 
```
ip link add nsmaster type veth peer name nsslave
```

* Assign the interfaces to the namespaces 
```
ip link set nsmaster netns ns01 
ip link set nsslave netns ns02 
```

* Change the names of the interfaces (I prefer to use standard interface names)
```
ip netns exec ns01 ip link set nsmaster name eth0
ip netns exec ns02 ip link set nsslave name eth0
```

* Assign an address to each interface
```
ip netns exec ns01 ip addr add 192.168.1.1/24 dev eth0
ip netns exec ns02 ip addr add 192.168.2.1/24 dev eth0
```

* Bring up the interfaces (the veth interfaces the loopback interfaces)
```
ip netns exec ns01 ip link set eth0 up 
ip netns exec ns01 ip link set lo up
ip netns exec ns02 ip link set eth0 up
ip netns exec ns02 ip link set lo up
```

* Configure routes 
```
ip netns exec ns01 ip route add default via 192.168.1.1 dev eth0
ip netns exec ns02 ip route add default via 192.168.2.1 dev eth0
```

### Test the connection

* Test in both directions
```
ip netns exec ns01 ping 192.168.2.1
ip netns exec ns02 ping 192.168.1.1
```

* List all rules in the PREROUTING chain of NAT table
```
ip netns exec ns01 iptables -t nat -L PREROUTING -nv
```

* Add a port redirect rule to PREROUTING chain of NAT table
```
ip netns exec ns01 iptables -t nat -A PREROUTING -p tcp --dport 9000 -j REDIRECT --to-ports 9000
```





ref.
https://unix.stackexchange.com/questions/405805/connecting-two-network-namespaces-via-a-veth-interface-pair-where-each-endpoint

http://fosshelp.blogspot.com/2014/07/create-network-namespace-iptables-rules.html



