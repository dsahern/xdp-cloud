// SPDX-License-Identifier: GPL-2.0
/* Example of L2 forwarding at tc ingress. FDB is a <vlan,dmac> hash table
 * returning device index to redirect packet.
 *
 * Copyright (c) 2019-2020 David Ahern <dsahern@gmail.com>
 */
#include <uapi/linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/if_vlan.h>
#include <linux/pkt_cls.h>
#include <bpf/bpf_helpers.h>

#include "xdp_fdb.h"

/* copy of 'struct ethhdr' without __packed */
struct eth_hdr {
	unsigned char   h_dest[ETH_ALEN];
	unsigned char   h_source[ETH_ALEN];
	unsigned short  h_proto;
};

/* <vlan,dmac> to device index map */
struct bpf_map_def SEC("maps") tc_fdb_map = {
	.type = BPF_MAP_TYPE_HASH,
	.key_size = sizeof(struct fdb_key),
	.value_size = sizeof(u32),
	.max_entries = 512,
};

SEC("tc_l2fwd")
int tc_l2fwd_prog(struct __sk_buff *skb)
{
	void *data_end = (void *)(long)skb->data_end;
	void *data = (void *)(long)skb->data;
	struct eth_hdr *eth = data;
	struct fdb_key key = {};
	u8 smac[ETH_ALEN];
	u16 h_proto = 0;
	u32 *entry;
	void *nh;
	int rc;

	/* set pointer to header after ethernet header */
	nh = data + sizeof(*eth);
	if (nh > data_end)
		goto pass_to_stack;

	key.vlan = skb->vlan_tci & VLAN_VID_MASK;
	if (key.vlan == 0)
		goto pass_to_stack;

	__builtin_memcpy(key.mac, eth->h_dest, ETH_ALEN);

	entry = bpf_map_lookup_elem(&tc_fdb_map, &key);
	if (!entry || *entry == 0)
		goto pass_to_stack;

	/* VM does not see vlan, so pop it */
	bpf_skb_vlan_pop(skb);

	return bpf_redirect(*entry, 0);

pass_to_stack:
	return TC_ACT_OK;
}

char _license[] SEC("license") = "GPL";
