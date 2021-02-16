#!/bin/bash

set -e

cf_ips_path="/etc/nginx/includes/cf_ips.conf"

echo "" > $cf_ips_path

curl -s https://www.cloudflare.com/ips-v4 | while read line; do echo "allow $line;" >> $cf_ips_path; done
curl -s https://www.cloudflare.com/ips-v6 | while read line; do echo "allow $line;" >> $cf_ips_path; done

sudo systemctl reload nginx

