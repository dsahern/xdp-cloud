/* SPDX-License-Identifier: GPL-2.0 */
#ifndef __LIBBPF_HELPERS_H
#define __LIBBPF_HELPERS_H

#include <bpf/libbpf.h>

int bpf_map_get_fd_by_name(const char *name);
int bpf_map_get_fd_by_path(const char *path);
int bpf_map_get_fd(__u32 id, const char *path, const char *name,
		   const char *desc);

int bpf_prog_get_fd_by_path(const char *path);
int bpf_prog_get_fd(__u32 id, const char *path, const char *name,
		    const char *desc);

#endif
