 openinfoman-ldif
================

OpenInfoman CSD Adapater for configuring LDIF (LDAP) exports

Prerequisites
=============

Assumes that you have installed BaseX and OpenInfoMan according to:
> https://github.com/openhie/openinfoman/wiki/Install-Instructions

and the OpenInfoMan CSV adapter
> https://github.com/openhie/openinfoman-csv

and the FunctX XQuery Library:
<pre>
 basex -Vc "REPO INSTALL http://files.basex.org/modules/expath/functx-1.0.xar"
</pre>

Directions
==========
<pre>
cd ~/
git clone https://github.com/openhie/openinfoman-ldif
cd ~/openinfoman-ldif/repo
basex -Vc "REPO INSTALL openinfoman_ldif_adapter.xqm"
cd ~/basex/resources/stored_query_definitions
ln -sf ~/openinfoman-ldif/resources/stored_query_definitions/* .
</pre>

