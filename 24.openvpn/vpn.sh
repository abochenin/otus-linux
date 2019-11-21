#!/bin/bash

vagrant destroy -f
rm -rf pki
vagrant up server

#mkdir pki
vagrant scp  server:/vagrant/pki/ ./pki/

#for a in ca.crt client.crt client.key; do vagrant scp pki/$a client:/vagrant/pki/; done

vagrant up client --no-provision
vagrant provision client
