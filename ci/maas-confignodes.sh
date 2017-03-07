#!/bin/bash

#set -ex

#defaults
labconfig_path=""
deployconfig_path=""

usage()
{
	echo "Usage: $0 -l labconfig.yaml [-d deployconfig.yaml]
	-l <string> : labconfig path
	-d <string> : already existing deployconfig.yaml. a new one will not be generated from the labconfig.yaml.

  the script expects that the relevant machines in MAAS are tagged with the tag joid.
	" 1>&2;
	exit 1;
}


while getopts ":l:td:r" o; do
	case "${o}" in
		l)
			labconfig_path=${OPTARG}
			;;
		d)
			deployconfig_path=${OPTARG}
			;;
		\?)
			echo "Invalid options: -$OPTARG" >&2
			usage
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			usage
			exit 1
			;;
		*)
			usage
			;;
	esac
done


if [[ -z "${labconfig_path}"  && -z "${deployconfig_path}" ]]; then usage; exit 1; fi
if [[ -n ${labconfig_path} && ! -e ${labconfig_path} ]]; then echo "labconfig file doesn't exist at ${labconfig_path}"; exit 1; fi
if [[ -n ${deployconfig_path} && ! -e ${deployconfig_path} ]]; then echo "deployconfig file doesn't exist at ${deployconfig_path}"; exit 1; fi

if [[ -z ${deployconfig_path} ]]; then
	deployconfig_path="deployconfig.yaml"
fi

echo "reading labconfig from: $labconfig_path"
labconfig=$(python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < ${labconfig_path})

if [[ -e ${deployconfig_path} ]]; then
	deployconfig=$(python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < ${deployconfig_path})
else
	deployconfig=$(python genDeploymentConfig.py -l ${labconfig_path} | python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)')
fi

#Wait until all nodes are Commissioned and in Ready state
#expecting the relevant machines are tagged with "joid"
while [ $(maas ubuntu machines read  | jq  -r ' map (select(.tag_names[] | contains("joid"))) | map(select(.status_name=="Commissioning")) | map(.system_id) | length') -gt 0 ]
do
  echo "machines still commissioning"
  sleep 10
done

echo "machines ready for configuration"
