# vc_hunter
vc_hunter is a search tool for veracrypt (truecrypt) containers that can be used to find encrypted Veracrypt or TrueCrypt containers on the system. 

vc_hunter scans a select folder on the computer for the following attributes that are part of every V/T-Crypt file:

- The suspect file size modulo 512 must equal zero.
- The suspect file contents has a high entropy.
- The suspect file must not contain a common file header. (at time in process)

Status: Beta
