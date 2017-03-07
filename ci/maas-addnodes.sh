#!/bin/bash

set -ex

#defaults
generate_tags=false
labconfig_path=""
deployconfig_path=""
remove_nodes=false

usage()
{
	echo "Usage: $0 -l labconfig.yaml [-t] [-d deployconfig.yaml] [-r]
	-l <string> : labconfig path
	-t : create the tags in maas before assigning them to the machines
	-d <string> : already existing deployconfig.yaml. a new one will not be generated from the labconfig.yaml.
	-r : remove all machines from maas before adding
	" 1>&2;
	exit 1;
}


while getopts ":l:td:r" o; do
	case "${o}" in
		l)
			labconfig_path=${OPTARG}
			;;
		t)
			generate_tags=true
			;;
		d)
			deployconfig_path=${OPTARG}
			;;
		r)
			remove_nodes=true
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

echo "setting up MAAS"
MAAS_IP="$(echo ${deployconfig} | jq --raw-output '.opnfv.ip_address')"
API_SERVER="http://$MAAS_IP/MAAS/api/2.0"
API_SERVERMAAS="http://$MAAS_IP/MAAS/"
PROFILE=ubuntu
SOURCE_ID=1
FABRIC_ID=1
PRIMARY_RACK_CONTROLLER="$MAAS_IP"
API_KEY=`sudo maas-region apikey --username=ubuntu`

echo "maas login $PROFILE $API_SERVERMAAS $API_KEY"
maas login $PROFILE $API_SERVERMAAS $API_KEY

if $generate_tags; then
	echo "Creating tags"
	##
	##TODO MAKE THE LIST OF TAGS CONFIGURABLE FROM THE labconfig.yaml
	##TODO get the tags from the roles and tags
	##
	for tag in bootstrap compute control storage opnfv
	do
			echo "creating tag $tag"
			maas $PROFILE tags create name=$tag || true
	done

	# specific tag for MEI disabled and console redirection on OCP servers
	echo "creating tag osv-ocpfix"
	maas $PROFILE tags create name="osv-ocpfix" comment='MEI disabled to avoid OCP reboot issues and ttyS4 redirection' kernel_opts='console=tty0 console=ttyS4 mei-me.disable_msi=1' || true
fi

if $remove_nodes; then
	echo "Removing all machines from MAAS"
	for m in $(maas $PROFILE machines read | jq -r '.[].system_id')
	do
			maas $PROFILE machine delete $m
	done
fi

createmachine()
{
	echo "create machine $mindex"
	index=$1
	NODE_NAME=$(echo ${labconfig} | jq -r ".lab.racks[0].nodes[$index].name")
	POWER_TYPE=$(echo ${labconfig} | jq -r ".lab.racks[0].nodes[$index].power.type")
	POWER_IP=$(echo ${labconfig} | jq -r ".lab.racks[0].nodes[$index].power.address")
	POWER_USER=$(echo ${labconfig} | jq -r ".lab.racks[0].nodes[$index].power.user")
	POWER_PASS=$(echo ${labconfig} | jq -r ".lab.racks[0].nodes[$index].power.pass")
	MAC_ADDRESS=$(echo ${labconfig} | jq -r ".lab.racks[0].nodes[$index].nics[] | select(.spaces[]==\"admin\").mac[0]")
	DOMAIN=$(echo ${labconfig} | jq -r ".lab.racks[0].nodes[$index].domain")
	DOMAIN_ID=$(maas $PROFILE domains read | jq -r ".[] | select(.name==\"$DOMAIN\") | .id")

  # echo $NODE_NAME
	# echo $DOMAIN $DOMAIN_ID
	# echo $MAC_ADDRESS
	# echo $POWER_TYPE $POWER_IP $POWER_USER $POWER_PASS

	maas $PROFILE machines create autodetect_nodegroup='yes' name=${NODE_NAME} \
			hostname=${NODE_NAME} power_type=$POWER_TYPE power_parameters_power_address=$POWER_IP \
			power_parameters_power_user=$POWER_USER power_parameters_power_pass=$POWER_PASS mac_addresses=$MAC_ADDRESS \
			architecture='amd64/generic' domain=$DOMAIN_ID
	machineid=$(maas $PROFILE machines read | jq -r '.[] | select(.hostname == '\"$NODE_NAME\"').system_id')

	#add tags
	for tags in $(echo ${labconfig} | jq -r ".lab.racks[0].nodes[$index].tags[]")
	do
		maas $PROFILE tag update-nodes ${tags} add=$machineid || true
	done

  #tag with the roles
	for tags in $(echo ${labconfig} | jq -r ".lab.racks[0].nodes[$index].roles[]")
	do
		maas $PROFILE tag update-nodes ${tags} add=$machineid || true
	done
}

for mindex in $(echo ${labconfig} | jq -r '.lab.racks[0].nodes | keys[]')
do
	createmachine $mindex
done
