
const yaml = require("yaml");

const str1 = `
---
foo: hello
bar:
  baz: 123
`;
const str2 = `
---
hello
`;
const str3 = `
---
location: huette15
location_nice: Huette15
latitude: 52.485032
longitude: 13.447244
contact_nickname: 'Packet Please'
contacts:
  - 'pktpls@systemli.org'

# alt, löschen:
# 2001:bf7:830:9a00::/56
# 10.31.77.200/30
# 10.31.77.196/30
# 10.31.112.192/26
# 10.31.112.128/27
# 10.31.77.13
# 10.31.77.55
# 10.31.77.56

# 10.31.184.0/26
# 10.31.184.0/29 - mgmt
# 10.31.184.8/29 - mesh
# 10.31.184.16/28 - prdhcp todo
# 10.31.184.32/27 - dhcp
ipv6_prefix: 2001:bf7:820:2400::/56

hosts:

  - hostname: huette15-core
    role: corerouter
    model: "x86-64"
    wireless_profile: disable

networks:

  - vid: 20
    role: mesh
    name: mesh_core
    prefix: 10.31.184.8/32
    ipv6_subprefix: 20

  - vid: 40
    role: dhcp
    inbound_filtering: true
    enforce_client_isolation: true
    prefix: 10.31.184.32/27
    ipv6_subprefix: 40
    assignments:
      huette15-core: 1

  - vid: 41
    role: dhcp
    name: prdhcp
    inbound_filtering: true
    enforce_client_isolation: false
    prefix: 10.31.184.16/28
    ipv6_subprefix: 41
    assignments:
      huette15-core: 1

  - vid: 42
    role: mgmt
    prefix: 10.31.184.0/29
    gateway: 1
    dns: 1
    ipv6_subprefix: 42
    assignments:
      huette15-core: 1
      huette15-switch: 2

  - vid: 50
    role: uplink

  - role: tunnel
    ifname: ts_wg0
    mtu: 1280
    prefix: 10.31.184.10/32
    wireguard_port: 51820

  - role: tunnel
    ifname: ts_wg1
    mtu: 1280
    prefix: 10.31.184.11/32
    wireguard_port: 51821
`;

printf("%J\n", yaml.yaml(str3));
