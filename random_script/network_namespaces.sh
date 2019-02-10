# https://ops.tips/blog/using-network-namespaces-and-bridge-to-isolate-servers/

# Creating the network namespaces   
#   two network namespace
#   two veth pairs
#   a bridge device that provides the routing

# start with the namespaces
ip netns add namespace1
ip netns add namespace2

ip netns show

#
ip netns exec namespace1 ip address show
ip netns exec namespace2 ip address show


# Creating and associating virtual ethernet pairs with the namespaces

# Create the two pairs.
ip link add veth1 type veth peer name br-veth1
ip link add veth2 type veth peer name br-veth2

# Associate the non `br-` side
# with the corresponding namespace
ip link set veth1 netns namespace1
ip link set veth2 netns namespace2


# associate ip addresses for namespaces.
ip netns exec namespace1 ip addr add 192.168.1.11/24 dev veth1
ip netns exec namespace2 ip addr add 192.168.1.12/24 dev veth2


# Creating and configuring the bridge device

# Create the bridge device naming it `br1`
# and set it up:
ip link add name br1 type bridge
ip link set br1 up

# Check that the device has been created.
ip link | grep br1


# Set the bridge veths from the default
# namespace up.
ip link set br-veth1 up
ip link set br-veth2 up


# Set the veths from the namespaces up too.
ip netns exec namespace1 ip link set veth1 up
ip netns exec namespace2 ip link set veth2 up


# Add the br-veth* interfaces to the bridge
# by setting the bridge device as their master.
ip link set br-veth1 master br1
ip link set br-veth2 master br1


# Check that the bridge is the master of the two
# interfaces that we set (i.e., that the two interfaces
# have been added to it).
bridge link show br1


# Set the address of the `br1` interface (bridge device)
# to 192.168.1.10/24 and also set the broadcast address
# to 192.168.1.255 (the `+` symbol sets  the host bits to 255).
ip addr add 192.168.1.10/24 brd + dev br1


# Check the connectivity from the default namespace (host)
ping 192.168.1.12

#/*
# We can also reach the interface of the other namespace
# given that we have a route to it.
ip netns exec namespace1 ip route
#*/


# Try to reach Google's DNS servers (8.8.8.8).
#
# Given that there's no route for something that doesn't 
# match the `192.168.1.0/24` range, 8.8.8.8 should be unreachable.
ip netns exec namespace1 ping 8.8.8.8


# 192.168.1.10 corresponds to the address assigned to the
# bridge device - reachable from both namespaces, as well as
# the host machine.
ip -all netns exec ip route add default via 192.168.1.10

#/*
ip netns exec namespace1 ip route add default via 192.168.1.11
ip netns exec namespace1 route -n
ip netns exec namespace2 ip route add default via 192.168.1.12
ip netns exec namespace2 route -n
#*/

# Try to reach Google's DNS servers (8.8.8.8).
ip netns exec namespace1 ping 8.8.8.8


# -t specifies the table to which the commands
# should be directed to. By default, it's `filter`.
#
# -A specifies that we're appending a rule to the
# chain that we tell the name after it;
#
# -s specifies a source address (with a mask in 
# this case).
#
# -j specifies the target to jump to (what action to
# take).
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j MASQUERADE


# Enable ipv4 ip forwarding
sysctl -w net.ipv4.ip_forward=1



#/*
ip -n namespace1 link add veth1 type veth peer name veth2 netns namespace2
ip netns exec namespace1 ip link add veth1 type veth peer name veth2 netns namespace2

iptables -t nat -A POSTROUTING -s 192.168.1.1/24 -d 0.0.0.0/0 -j MASQUERADE
#*/


##################################

# https://serverfault.com/questions/568839/linux-network-namespaces-ping-fails-on-specific-veth

sysctl -q net.ipv4.ip_forward=1
ip netns add vpn
ip link add veth0 type veth peer name eth0
ip link set eth0 netns vpn
ip addr add 10.0.0.1/24 dev veth0
ip netns exec vpn ip addr add 10.0.0.2/24 dev eth0
ip link set veth0 up
ip netns exec vpn ip link set eth0 up

ip netns exec vpn ip route add default via 10.0.0.1 dev eth0
ip netns exec vpn ip addr add 127.0.0.1 dev lo
ip netns exec vpn ip link set lo up

iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -d 0.0.0.0/0 -j MASQUERADE

ip netns exec vpn ping 10.0.0.1
ip netns exec vpn ping 10.0.0.2



####################################################
# https://unix.stackexchange.com/questions/405805/connecting-two-network-namespaces-via-a-veth-interface-pair-where-each-endpoint

# Create two network namespaces
ip netns add 'mynamespace-1'
ip netns add 'mynamespace-2'

# Create a veth virtual-interface pair
ip link add 'myns-1-eth0' type veth peer name 'myns-2-eth0'

# Assign the interfaces to the namespaces
ip link set 'myns-1-eth0' netns 'mynamespace-1'
ip link set 'myns-2-eth0' netns 'mynamespace-2'

# Change the names of the interfaces (I prefer to use standard interface names)
ip netns exec 'mynamespace-1' ip link set 'myns-1-eth0' name 'eth0'
ip netns exec 'mynamespace-2' ip link set 'myns-2-eth0' name 'eth0'

# Assign an address to each interface
ip netns exec 'mynamespace-1' ip addr add 192.168.1.1/24 dev eth0
ip netns exec 'mynamespace-2' ip addr add 192.168.2.1/24 dev eth0

# Bring up the interfaces (the veth interfaces the loopback interfaces)
ip netns exec 'mynamespace-1' ip link set 'lo' up
ip netns exec 'mynamespace-1' ip link set 'eth0' up
ip netns exec 'mynamespace-2' ip link set 'lo' up
ip netns exec 'mynamespace-2' ip link set 'eth0' up

# Configure routes
ip netns exec 'mynamespace-1' ip route add default via 192.168.1.1 dev eth0
ip netns exec 'mynamespace-2' ip route add default via 192.168.2.1 dev eth0

# Test the connection (in both directions)
ip netns exec 'mynamespace-1' ping 192.168.2.1
ip netns exec 'mynamespace-2' ping 192.168.1.1

# Test the connection (in both directions)
ip netns exec 'mynamespace-1' ping -c 1 192.168.2.1
ip netns exec 'mynamespace-2' ping -c 1 192.168.1.1


###################################################################################
# worked

ip link add name br1 type bridge
#/*
brctl stp br1 off
ip link set dev br1 up
#*/

ip link add ns01master type veth peer name ns01slave
ip link add ns02master type veth peer name ns02slave

brctl addif br1 ns01master
brctl addif br1 ns02master

brctl show

ip netns add ns01
ip link set ns01slave netns ns01 name eth0
ip netns exec ns01 ip addr add 10.1.1.4/24 dev eth0

ip netns add ns02
ip link set ns02slave netns ns02 name eth0
ip netns exec ns02 ip addr add 10.1.1.5/24 dev eth0

# ip addr add 192.168.1.10/24 brd + dev br1
sysctl -w net.ipv4.ip_forward=1
ip netns exec ns01 ip route
ip netns exec ns02 ip route
#

ip link set br1 up

ip netns exec ns01 ip link set eth0 up
ip netns exec ns02 ip link set eth0 up

ip netns exec ns01 ip link set lo up
ip netns exec ns02 ip link set lo up

ip link set ns01master up
ip link set ns02master up

ip netns exec ns01 ip route add default via 10.1.1.4
ip netns exec ns02 ip route add default via 10.1.1.5

ip netns exec ns01 ping 10.1.1.4
ip netns exec ns01 ping 10.1.1.5
ip netns exec ns02 ping 10.1.1.5
ip netns exec ns02 ping 10.1.1.4


###################################################################################
# worked2
# http://fosshelp.blogspot.com/2014/08/connect-two-network-namespaces-using.html

ip netns add ns1
ip netns add ns2

brctl addbr br-test
brctl stp br-test off
ip link set dev br-test up

ip link add tap1 type veth peer name br-tap1
ip link set tap1 netns ns1

brctl addif br-test br-tap1 
ip netns exec ns1 ip link set dev tap1 up
ip link set dev br-tap1 up


ip link add tap2 type veth peer name br-tap2
ip link set tap2 netns ns2
brctl addif br-test br-tap2 


ip netns exec ns1 ip addr add 10.1.1.4/24 dev tap1
ip netns exec ns2 ip addr add 10.1.1.5/24 dev tap2

ip netns exec ns1 ip link set lo up
ip netns exec ns2 ip link set lo up


ip netns exec ns1 ping 10.1.1.5


##
ip link add myns-1-eth0 type veth peer name myns-2-eth0
ip link set myns-1-eth0 netns ns1
ip link set myns-2-eth0 netns ns2
ip netns exec ns1 ip link set myns-1-eth0 name eth0
ip netns exec ns2 ip link set myns-2-eth0 name eth0
# Assign an address to each interface
ip netns exec ns1 ip addr add 192.168.1.1/24 dev eth0
ip netns exec ns2 ip addr add 192.168.2.1/24 dev eth0

ip netns exec ns1 ip link set eth0 up
ip netns exec ns2 ip link set eth0 up

ip netns exec ns1 ip route add default via 192.168.1.1 dev eth0
ip netns exec ns2 ip route add default via 192.168.2.1 dev eth0

ip netns exec ns1 ping 192.168.2.1









