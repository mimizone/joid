#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
This script generates a deployment config based on lab config file.

Parameters:
 -l, --lab      : lab config file
"""

import myipaddr
from optparse import OptionParser
from jinja2 import Environment, FileSystemLoader
from distutils.version import LooseVersion, StrictVersion
import os
import yaml
import subprocess
import socket
import fcntl
import struct

#
# Parse parameters
#

parser = OptionParser()
parser.add_option("-l", "--lab", dest="lab", help="lab config file")
(options, args) = parser.parse_args()
labconfig_file = options.lab

#
# Set Path and configs path
#

# Capture our current directory
jujuver = subprocess.check_output(["juju", "--version"])

if LooseVersion(jujuver) >= LooseVersion('2'):
    TPL_DIR = os.path.dirname(os.path.abspath(__file__))+'/config_tpl/juju2'
else:
    TPL_DIR = os.path.dirname(os.path.abspath(__file__))+'/config_tpl'

HOME = os.environ['HOME']
USER = os.environ['USER']

#
# Prepare variables
#

# Prepare a storage for passwords
passwords_store = dict()

#
# Local Functions
#


def load_yaml(filepath):
    """Load YAML file"""
    with open(filepath, 'r') as stream:
        try:
            return yaml.load(stream)
        except yaml.YAMLError as exc:
            print(exc)


def get_ip_address(ifname):
    """Get local IP"""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', bytes(ifname.encode('utf-8')[:15]))
    )[20:24])






#
# Config import
#

#
# Config import
#

# Load scenario Config
config = load_yaml(labconfig_file)

# Set a dict copy of opnfv/spaces
config['opnfv']['spaces_dict'] = dict()
for space in config['opnfv']['spaces']:
    config['opnfv']['spaces_dict'][space['type']] = space

# Set a dict copy of opnfv/storage
config['opnfv']['storage_dict'] = dict()
for storage in config['opnfv']['storage']:
    config['opnfv']['storage_dict'][storage['type']] = storage

# Add some OS environment variables
config['os'] = {'home': HOME,
                'user': USER,
                'brAdmIP': get_ip_address(config['opnfv']['spaces_dict']
                                                ['admin']['bridge'])}

# Prepare interface-enable, more easy to do it here
ifnamelist = set()
for node in config['lab']['racks'][0]['nodes']:
    for nic in node['nics']:
        if 'admin' not in nic['spaces']:
            ifnamelist.add(nic['ifname'])
config['lab']['racks'][0]['ifnamelist'] = ','.join(ifnamelist)

#
# Transform template to deployconfig.yaml according to config
#

# Create the jinja2 environment.
env = Environment(loader=FileSystemLoader(TPL_DIR),
                  trim_blocks=True)
## IPADDRR FILTER FOR JINJA2 template
## CODE COPIED FROM ANSIBLE
## https://github.com/drybjed/ansible-ipaddr-filter/blob/master/filter_plugins/ipaddr.py
env.filters.update(myipaddr.FilterModule().filters())

template = env.get_template('deployconfigOSV.yaml')

# Render the template
output = template.render(**config)

# Check output syntax
try:
    yaml.load(output)
except yaml.YAMLError as exc:
    print(exc)

# print output
print(output)
