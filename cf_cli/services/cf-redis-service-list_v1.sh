#!/bin/bash
set -e
#set -euo pipefail

validate_environment() {
  which cf > /dev/null || { echo "cf cli is required - please install it"; exit 1; }
  which jq > /dev/null || { echo "jq is required - please install it"; exit 1; }
  which bc > /dev/null || { echo "bc is required - please install it"; exit 1; }

}

case $1 in
-h|--h|help|-help|--help|-h|\?|-\?|--\? )
	echo  "Usage: ./cf-redis-service-list_v1.sh"
	echo
	echo  "cf-redis-service-list_v1.sh will obtain all Service Instances (SI)'s that have been"
	echo  "created by a redis service broker and list the associated service broker,"
	echo  "service plan, Service Instance (SI) name, # of bound apps and app names (if any)"
	echo  "age of each Service Instance (SI), and the ORG/Space to which they belong"
	echo  
	echo  "requires: jq, cf cli, bc"
	echo
	exit 0
esac

validate_environment

RED='\033[0;31m' # Red
RED_BOLD="\033[1;31m"
GREEN="\033[0;32m"
GREEN_BOLD="\033[1;32m"
YELLOW_BOLD="\033[1;33m"
BLUE="\033[0;34m"
BLUE_BOLD="\033[1;34m"
MAGENTA_BOLD="\033[1;35m"
CYAN_BOLD="\033[1;36m"
BOLD="\033[1m"
GREY="\033[1;30m"
RESET="\033[0m"

NC='\033[0m' # No Color

VERSION="(build 1)"

if [[ $1 == "-v" || $1 == "-version" || $1 == "--version" ]]; then
	echo -e "cf-redis-service-list_v1.sh ${BOLD}${VERSION}${RESET}"
	exit 0
fi

debug() {
	if [[ -n ${DEBUG} && ${DEBUG} != '0' ]];
		then echo >&2 '>> ' "$*"
	fi
}

function cf_curl() {
	set -e
	url=$1
	if [ "$(uname)" == "Darwin" ]; then
	md5=$(echo "${url}" | md5 | cut -f1 -d " ")
	else
	md5=$(echo "${url}" | md5sum | cut -f1 -d " ")
	fi
	path="${tmpdir}/${md5}"
	if [[ ! -f $path ]]; then
		debug "No cached data found - cf curl ${url}"
		cf curl "${url}" > ${path}
	fi
	echo ${path}
}

function process_serviceinstance() {
	set -e
	service_instance_guid=$1
	service_name=$(cat $(cf_curl /v2/service_instances/${service_instance_guid}) | jq -r '.entity.name')
	service_instance_creation_time=$(cat $(cf_curl /v2/service_instances/${service_instance_guid}) | jq -r '.metadata.created_at')
	age_in_days=$(( ($(date -j +%s) - $(date -jf '%Y-%m-%dT%H:%M:%SZ' "$service_instance_creation_time" +%s)) / 24 / 3600))
	n=0
	next_bindings_url="/v2/service_bindings?q=service_instance_guid:${service_instance_guid}"
	apps=""
	count=$(cat $(cf_curl ${next_bindings_url}) | jq -r '.total_results')

	debug "    found service ${service_name} with guid {${service_instance_guid}}"
	space_guid=$(cat $(cf_curl /v2/service_instances/${service_instance_guid}) | jq -r '.entity.space_guid')
	space_name=$(cat $(cf_curl /v2/spaces/${space_guid}) | jq -r '.entity.name')
	debug "    -- in ${org_name} / ${space_name}"
	org_guid=$(cat $(cf_curl /v2/spaces/${space_guid}) | jq -r '.entity.organization_guid')
	org_name=$(cat $(cf_curl /v2/organizations/${org_guid}) | jq -r '.entity.name')
        service=$(cf curl /v2/services | jq -r --arg svc $broker_guid '.resources[].entity | select(.service_broker_guid == $svc) | .label')
	if [[ ${count} > 0 ]]; then
		next_bindings_url="/v2/service_bindings?q=service_instance_guid:${service_instance_guid}"
		while [[ ${next_bindings_url} != "null" ]]; do
			for app_guid in $(cat $(cf_curl ${next_bindings_url}) | jq -r '.resources[].entity.app_guid'); do
				app_name=$(cat $(cf_curl /v2/apps/${app_guid}) | jq -r '.entity.name')
				debug "      found app '${app_name}' with guid {${app_guid}}"


				app_name=${app_name:-(${app_guid})}
				if [[ $n == 0 ]]; then
					echo -ne "${service}\t${service_plan_name}\t${service_name}\t${count}\t"
				else
					echo -ne " \t \t \t \t"
				fi
				echo -e "${app_name}\t${org_name}\t${space_name}\t${age_in_days}"
				n=$(( n + 1 ))
			done

			next_bindings_url=$(cat $(cf_curl ${next_bindings_url}) | jq -r -c ".next_url")
		done
	else
		echo -e "${service}\t${service_plan_name}\t${service_name}\t${n}\t \t${org_name}\t${space_name}\t${age_in_days}"
	fi
}

function traverse_serviceinstances_for_plan() {
	set -e
	service_plan_guid=$1
	service_plan_name=$(cf curl /v2/service_plans/$service_plan_guid | jq -r '.entity.name') 
	echo -ne "Found Service Instances with plan:  ${BLUE}${service_plan_name}${RESET}... \n" >&2
	next_serviceinstance_url="/v2/service_instances?q=service_plan_guid:${service_plan_guid}"
	while [[ ${next_serviceinstance_url} != "null" ]]; do
		for service_instance_guid in $(cat $(cf_curl ${next_serviceinstance_url}) | jq -r '.resources[].metadata.guid'); do
			debug "    found service instance '${service_name}' with guid {${service_instance_guid}}"
			process_serviceinstance ${service_instance_guid}
		done
		next_serviceinstance_url=$(cat $(cf_curl ${next_serviceinstance_url}) | jq -r -c ".next_url")
	done
}

function traverse_serviceplans_for_broker() {
	set -e
	broker_guid=$1
	echo -ne "Traversing through Service Plans for ${GREEN}${broker}${RESET}... \n" >&2
	next_serviceplan_url="/v2/service_plans?q=service_broker_guid:${broker_guid}"
	while [[ ${next_serviceplan_url} != "null" ]]; do
		for service_plan_guid in $(cat $(cf_curl ${next_serviceplan_url}) | jq -r '.resources[].metadata.guid'); do
			debug "  found service plan guid {${service_plan_guid}} for service"
			traverse_serviceinstances_for_plan ${service_plan_guid}
		done
		next_serviceplan_url=$(cat $(cf_curl ${next_serviceplan_url}) | jq -r -c '.next_url')
	done
}

function services_for_broker() {
	set -e
        echo -e "${BOLD}Service\t   Service_Plan\t   Service_Name\t   #_bound_apps\t   Bound Application(s)\t   Organization\t   Space\t   Age_In_Days${RESET}"
        echo -e "-------\t------------\t------------\t------------\t--------------------\t------------\t-----\t-----------"
	for broker in `cf curl /v2/service_brokers | jq -r '.resources[].entity | select(.name | contains ("redis")) | .name'`
	do
	echo -ne "Collecting data for ${GREEN_BOLD}${broker}${RESET} service... \n" >&2
	broker_count=$(cat $(cf_curl /v2/service_brokers?q=name:${broker}) | jq -r '.total_results')
	if [[ ${broker_count} == 0 ]]; then
		echo "Could not find broker '${broker}'" >&2
		exit 1
	else
		if [[ ${broker_count} != 1 ]]; then
			echo "Too many brokers found matching '${broker}'! Try narrowing your search" >&2
			exit 1
		fi
	fi
	broker_guid=$(cat $(cf_curl /v2/service_brokers?q=name:${broker}) | jq -r '.resources[].metadata.guid')
	debug "broker '${broker}' has guid {${broker_guid}}"

	traverse_serviceplans_for_broker ${broker_guid}
done
}

tmpdir=$(mktemp -d)
trap 'rm -rf ${tmpdir:?nothing to remove}' INT TERM QUIT EXIT
debug "set up workspace directory ${tmpdir}"
services_for_broker | column -t -s "	"
