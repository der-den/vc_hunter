# vc_hunter
vc_hunter is a search tool for veracrypt (truecrypt) containers that can be used to find encrypted Veracrypt or TrueCrypt containers on the system. 

vc_hunter scans all files in a select folder on the computer and with follow conditions:

- file size is over 4kb (entropy is generated from the first 4kb of a file)

Hint: the minimal size of a veracrypt container is 292kb (with FAT filesystem, 424kb = exFAT, 3792kb = NTFS).

- file size modulo 512 must equal zero
- file contents has a high entropy
- file has a byte difference under 160 (experimental)

- file must not contain a common file header (optional)

Status: Beta
