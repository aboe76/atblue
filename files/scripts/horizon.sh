#!/usr/bin/env bash
set -euo pipefail

rpm -Uvh --noscripts https://download3.omnissa.com/software/CART26FQ2_LIN64_RPMPKG_2506/Omnissa-Horizon-Client-2506-8.16.0-16536624989.x64.rpm

mv /usr/lib/omnissa/libcrypto.so.3 /usr/lib/omnissa/libcrypto.so.3.old
mv /usr/lib/omnissa/libssl.so.3 /usr/lib/omnissa/libssl.so.3.old

ln -s /usr/lib64/libcrypto.so.3 /usr/lib/omnissa/libcrypto.so.3
ln -s /usr/lib64/libssl.so.3 /usr/lib/omnissa/libssl.so.3


