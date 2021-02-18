#!/bin/bash
#
# Simple setup to test XDP forwarding.
#
#   switch   |               host           | container
#   tap_sw --|-- tap_host -- br0 -- veth1 --|-- veth2 

################################################################################
# XDP init

BPFFS="/sys/fs/bpf"
BPFTOOL="sudo bpftool"

sudo mkdir -p ${BPFFS}/map

${BPFTOOL} map create ${BPFFS}/map/xdp_fwd_ports  \
	type devmap_hash key 4 value 8 entries 512 name xdp_fwd_ports

${BPFTOOL} map create ${BPFFS}/map/fdb_map  \
	type hash key 8 value 4 entries 512 name fdb_map

sudo mkdir -p ${BPFFS}/prog

${BPFTOOL} prog load ../ksrc/obj/xdp_l2fwd.o ${BPFFS}/prog/xdp_l2fwd \
	map name xdp_fwd_ports name xdp_fwd_ports \
	map name fdb_map name fdb_map

${BPFTOOL} prog load ../ksrc/obj/xdp_dummy.o  ${BPFFS}/prog/xdp_dummy

################################################################################
#
# setup switch - host - container

# sudo sysctl -wq net.ipv4.ip_forward=1

sudo ip netns add switch
sudo ip tuntap add mode tap dev tap_sw
sudo ip li set tap_sw netns switch up
sudo ip -netns switch addr add dev tap_sw 10.1.1.1/24

sudo ip li add br0 type bridge
sudo ip li set br0 up
sudo ip addr add dev br0 10.1.1.254/24

sudo ip tuntap add mode tap dev tap_host
sudo ip li set tap_host up master br0

sudo ip li add veth1 type veth peer veth2
sudo ip li set veth1 up master br0

# need to add dummy program on veth2 before changing namespaces
${BPFTOOL} net attach xdp pinned ${BPFFS}/prog/xdp_dummy dev veth2

sudo ip netns add container
sudo ip li set veth2 netns container up
sudo ip -netns container addr add dev veth2 10.1.1.2/24

# fowarding from switch to host tap devices
# - mimics veth pairs for connecting host to switch
# - allows running XDP programs on tap device
sudo ./tap_fwd tap_host tap_sw switch &

echo -n "Verify connectivity ...    "

# generate traffic towards container
# - first one is to get past the initial setup and arp
sudo ip netns exec switch ping -c1 10.1.1.2 >/dev/null 2>&1

# - expect all of these to succeed
sudo ip netns exec switch ping -c3 10.1.1.2 >/dev/null 2>&1
if [ $? -ne 0 ]
then
	echo "FAIL"
	exit 1
fi
echo "PASS"
echo

################################################################################
# configure XDP
#
# Add FDB and port map entries for container
MAC=$(sudo ip -netns container -j li sh dev veth2 |  jq -r '.[]["address"]')
sudo ../src/bin/xdp_l2fwd -f /sys/fs/bpf/map/fdb_map \
                       -t /sys/fs/bpf/map/xdp_fwd_ports \
                       -m ${MAC} -d veth1

# Add FDB and port map entries for container egress
MAC=$(sudo ip -netns switch -j li sh dev tap_sw |  jq -r '.[]["address"]')
sudo ../src/bin/xdp_l2fwd -f /sys/fs/bpf/map/fdb_map \
                       -t /sys/fs/bpf/map/xdp_fwd_ports \
                       -m ${MAC} -d tap_host

#sudo ../src/bin/xdp_l2fwd -f /sys/fs/bpf/map/fdb_map \
#                       -t /sys/fs/bpf/map/xdp_fwd_ports \
#                       -P

# host ingress device gets forwarding program
# - redirect packets from host ingress to container
${BPFTOOL} net attach xdp pinned ${BPFFS}/prog/xdp_l2fwd dev tap_host

# configure container egress program
# - redirect packets from container to host egress
${BPFTOOL} net attach xdp pinned ${BPFFS}/prog/xdp_l2fwd dev veth1 

################################################################################
# detach from bridge - proves forwarding is in XDP
sudo ip li set veth1 nomaster

sudo ip netns exec switch ping -c1 -w1 10.1.1.2
rc=$?
echo -n "XDP Functional ...    "
if [ $rc -eq 0 ]
then
	echo "PASS"
else
	echo "FAIL"
fi
