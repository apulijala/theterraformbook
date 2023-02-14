#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y software-properties-common
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update -y
sudo apt-get install ansible -y
sudo ansible-playbook -i /tmp/inventory /tmp/playbook.yaml
