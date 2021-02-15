/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _STR_UTILS_H_
#define _STR_UTILS_H_

int str_to_int(const char *str, int min, int max, int *value);
int str_to_ulong(const char *str, unsigned long *ul);
int str_to_ullong(const char *str, unsigned long long *ul);
int str_to_mac(const char *str, unsigned char *mac);
void print_mac(const __u8 *mac, bool reverse);

#endif
