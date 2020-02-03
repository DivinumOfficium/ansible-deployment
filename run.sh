#!/bin/bash

#time ansible-playbook --ask-become-pass -i inventory playbook.yml
time ansible-playbook -i inventory playbook.yml
