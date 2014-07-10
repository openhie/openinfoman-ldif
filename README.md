openinfoman-ldif
================

OpenInfoman CSD Adapater for configuring LDIF (LDAP) exports

Prerequisites
=============

Assumes that you have installed BaseX and OpenInfoMan according to:
  https://github.com/openhie/openinfoman/wiki/Install-Instructions
and the OpenInfoMan CSV adapter
  https://github.com/openhie/openinfoman-csv

Directions
==========
cd ~/
git clone https://github.com/openhie/openinfoman-ldif
cd ~/opeinfoman-ldif/repo
~/basex/bin/basex -Vc "REPO INSTALL openinfoman_ldif_adapter.xqm"
cd ~/basex/resources/stored_query_definitions
ln -sf ~/openinfoman-ldif/resources/stored_query_definitions/* .

