#!/usr/bin/env bash
set -euo pipefail

#rpm -Uvh --noscripts https://download3.omnissa.com/software/CART26FQ2_LIN64_RPMPKG_2506/Omnissa-Horizon-Client-2506-8.16.0-16536624989.x64.rpm
#rpm -Uvh --noscripts https://download3.omnissa.com/software/CART25FQ4_LIN64_RPMPkg_2412/Omnissa-Horizon-Client-2412-8.14.0-12437214089.x64.rpm
curl -L https://download3.omnissa.com/software/CART25FQ4_LIN64_RPMPkg_2412/Omnissa-Horizon-Client-2412-8.14.0-12437214089.x64.rpm -o /tmp/Omnissa-Horizon-Client-2412-8.14.0-12437214089.x64.rpm
sudo dnf install -y /tmp/Omnissa-Horizon-Client-2412-8.14.0-12437214089.x64.rpm && rm /tmp/Omnissa-Horizon-Client-2412-8.14.0-12437214089.x64.rpm


#mv /usr/lib/omnissa/libcrypto.so.3 /usr/lib/omnissa/libcrypto.so.3.old
#mv /usr/lib/omnissa/libssl.so.3 /usr/lib/omnissa/libssl.so.3.old
#mv /usr/lib/omnissa/libcurl.so.4 /usr/lib/omnissa/libcurl.so.4.old

#ln -s /usr/lib64/libcrypto.so.3 /usr/lib/omnissa/libcrypto.so.3
#ln -s /usr/lib64/libssl.so.3 /usr/lib/omnissa/libssl.so.3
#ln -s /usr/lib64/libcurl.so.4 /usr/lib/omnissa/libcurl.so.4


