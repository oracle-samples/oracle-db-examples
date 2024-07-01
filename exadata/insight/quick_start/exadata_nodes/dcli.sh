#!/bin/bash

## Use dcli to automate creation of user on Storage Servers
## Run as root
## Assumes ssh equlivancy has been configured

dcli -g cells -l root -x create_exadata_user.scl
dcli -g dbnodes -l root -x create_exadata_user_db.sh
