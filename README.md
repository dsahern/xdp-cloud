# xdp-cloud

## XDP L2 forwarding

xdp\_l2fwd handles Layer 2 forwarding between an ingress device (e.g., host
devices) and egress device (e.g., tap device for VMs, veth for containers).
Userspace populates an FDB (hash map) with \<vlan,dmac> pairs that returns
an index into a device map. The device map is used to redirect the packets.


Install bpftool.
  Ubuntu 20.10: sudo apt install linux-tools-common linux-tools-$(uname -r)

BPFFS="/sys/fs/bpf"
BPFTOOL="sudo bpftool"

Create a pinned, global ports map for managing where packets are redirected:
  sudo mkdir -p ${BPFFS}/map

  ${BPFTOOL} map create ${BPFFS}/map/xdp\_fwd\_ports \
       type devmap_hash key 4 value 8 entries 512 name xdp_fwd_ports

Create a pinned, global fdb map for managing vlan,dmac to device index
lookups:

  ${BPFTOOL} map create ${BPFFS}/map/fdb\_map \
       type hash key 4 value 8 entries 512 name fdb\_map

Load program using the global maps and attach to ingress interface, e.g., eth0
  sudo mkdir -p ${BPFFS}/prog

  ${BPFTOOL} prog load ksrc/obj/xdp\_l2fwd.o ${BPFFS}/prog/xdp\_l2fwd \
       map name xdp\_fwd\_ports name xdp\_fwd\_ports \
       map name fdb\_map name fdb\_map

  ${BPFTOOL} net attach xdp pinned ${BPFFS}/prog/xdp\_l2fwd dev eth0

Add FDB and port map entries for VMs or containers:
  src/bin/xdp\_l2fwd -m ${MAC} -d veth1
  src/bin/xdp\_l2fwd -P
