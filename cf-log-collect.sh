#!/bin/bash

#set -eu

set -o pipefail

extra_logs=""
cell_load_min=""
datestring="$(date +%Y-%m-%d-%H-%M-%S)"
output_dir=$(pwd)
output_file="${datestring}-piv-support-logs.tar.gz"
bosh=`which bosh`

function usage(){
  >&2 echo "Usage: 
  "Ex: ./cf-log-collect.sh -X"
  -X (Optional) Include selected instance/job system process stats and BOSH Agent logs

  This program will obtain the following for all selected bosh instances (from Menu):
	1. BOSH JOB logs
	2. bosh instances --details
	3. bosh vms --vitals 
	4. bosh deployments list
  
  If using -X flag the following logs will also be collected for each selected instance:
	1. BOSH Agent logs
	2. /var/vcap/data/root_log/* (sysstat/kernel logs..etc)
	3. /var/vcap/monit/monit.log
	4. Instance:
		- ps auxwf; pstree -panl; ps -eLo pid,tid,ppid,user:11,comm,state,wchan
		- ifconfig
		- free -h; df -h
		- vmstat -S M 1 3; iostat -txm 1 3; netstat -ntlp; netstat -aW 
		- lsblk -a g
		- iptables --list

  The output directory is your current working director: ${output_dir}

  This tool requires the bosh v2 cli and the following environment variables to be set:
	BOSH_ENVIRONMENT
	BOSH_CLIENT_SECRET
	BOSH_CLIENT
	BOSH_CA_CERT
	BOSH_DEPLOYMENT

  Optionally if you require communicating with your BOSH director through a gateway, you must set:
	BOSH_GW_PRIVATE_KEY; BOSH_GW_USER; BOSH_GW_HOST

  Example Menu format:
     Jobs in deployment: cf-b8a0cd3a767cd0eeca66
	[ ] 1) "clock_global/83246a6a-fcc4-4a79-b0ff-1582eb90da7c"
	[ ] 2) "cloud_controller/6ff71454-8b04-45d0-a94f-160e3a2fc4e8"
	[*] 3) "cloud_controller_worker/bf10105a-6850-443c-ad99-d886cf2e3afc"
	[ ] 4) "consul_server/a9ba1509-3a6e-4b8a-bdd6-49986133697b"
	[ ] 5) "credhub/4e4f2d6a-0da4-4f87-bab1-c80d03bc8e83"
	[*] 6) "diego_brain/09131c43-f438-4fb0-a8ed-68d6821d46fd"
	[*] 7) "diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78"
	[*] 8) "diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f"
	[*] 9) "diego_cell/ce6a04ea-33f1-4e01-9ed6-f42470242ed7"
	[ ] 10) "diego_database/f16a141f-7907-4373-a3cd-d72e7dd874d3"
	[ ] 11) "doppler/585b5943-51d8-4421-8d64-533986648bed"
	[ ] 12) "ha_proxy/b10ce83d-4116-41b0-9dd0-3be0981b3cbc"
	[ ] 13) "loggregator_trafficcontroller/51f936c8-0062-4f8e-84f3-5152680b284d"
	[ ] 14) "mysql/0079a88c-e317-440a-bf4e-01c28b01b152"
	[ ] 15) "mysql/15b595eb-7c9d-42ff-bb45-025ac47f4726"
	[ ] 16) "mysql/e4dfcbcb-8943-43ee-a7a2-025df2b4f0c0"
	[ ] 17) "mysql_monitor/e977aab8-0c96-4cc4-9071-a94010c1430f"
	[ ] 18) "mysql_proxy/792df664-5e7d-45e5-a36a-ca6567e41da9"
	[ ] 19) "mysql_proxy/8015a342-fa9f-4f89-8dcf-70d1fee78fa7"
	[ ] 20) "nats/0f6844f1-c458-4379-8a3e-696fc9321898"
	[ ] 21) "nfs_server/6ddb3b9a-6a45-495a-84c6-544fb6bc5487"
	[ ] 22) "router/adcdb4c1-a95e-4110-831c-1d6d94090a6b"
	[ ] 23) "service-discovery-controller/a364811a-df3f-4a95-ae89-52f431cf78e5"
	[ ] 24) "syslog_adapter/3b1111ce-e037-47eb-814e-ea0a12d9fbc6"
	[ ] 25) "syslog_scheduler/b17adc08-9bad-4e19-991a-980666e2322f"
	[ ] 26) "tcp_router/fdaed2e4-d5f2-444e-808e-1a8a96db96e8"
	[ ] 27) "uaa/09c15325-cd2f-4311-bc8b-3824ca7d21bd"

	Select BOSH Job(s) using their number (again to uncheck, ENTER when done): 
	BOSH Jobs selected:
		cloud_controller_worker/bf10105a-6850-443c-ad99-d886cf2e3afc
		diego_brain/09131c43-f438-4fb0-a8ed-68d6821d46fd
		diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
		diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
		diego_cell/ce6a04ea-33f1-4e01-9ed6-f42470242ed7

  "
  exit 1
}


function check_fast_fails() {
  if [ -z "${BOSH_ENVIRONMENT}" ] || [ -z "${BOSH_CLIENT_SECRET}" ] || [ -z "${BOSH_CLIENT}" ] || [ -z "${BOSH_CA_CERT}" ] || [ -z "${BOSH_DEPLOYMENT}" ] ; then
    echo "BOSH_DEPLOYMENT, BOSH_ENVIRONMENT, BOSH_CLIENT_SECRET, BOSH_CLIENT, and BOSH_CA_CERT are required environment variables"
	echo -e "PLEASE Export the required Environment Variables\n"
    usage
  fi
}

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

function get_vm_and_deployments_info() {
  echo -e "${GREEN}Temporary Directory: ${RESET}${tempdir}\n"
  echo -e "${BOLD}[INFO]${RESET} Retrieving deployment and job info for deployment: ${BLUE_BOLD}$BOSH_DEPLOYMENT${RESET}..."
  $bosh -d $BOSH_DEPLOYMENT instances --column=Instance --column=Process_State  > ${tempdir}/bosh_job_details/bosh_all_job_file.out
  echo -e " - collecting 'bosh deployment'"
  $bosh --tty deployments &> "${tempdir}/bosh_job_details/deployments"
  echo -e " - collecting 'bosh instance --details'"
  $bosh --tty instances --details &> "${tempdir}/bosh_job_details/instances.details"
  echo -e " - collecting 'bosh vms --vitals'\n"
  $bosh --tty vms --vitals &> "${tempdir}/bosh_job_details/vms.vitals"
  total_bosh_jobs=$(cat ${tempdir}/bosh_job_details/bosh_all_job_file.out | wc -l)
  if cat ${tempdir}/bosh_job_details/bosh_all_job_file.out | grep -qv running; then cat ${tempdir}/bosh_job_details/bosh_all_job_file.out | grep -v running > ${tempdir}/bosh_job_details/failing_instances.out; not_running=$(cat ${tempdir}/bosh_job_details/failing_instances.out | wc -l); echo -e "${MAGENTA_BOLD}[WARNING]${RESET} There are ${not_running} instances not running\n"; while IFS='' read -r line || [[ -n "$line" ]]; do instance_state=$(echo $line | awk {'print $2'});instance_name=$(echo $line | awk {'print $1'}); echo -e "instance ${instance_name} is in state: ${instance_state}.."; done < ${tempdir}/bosh_job_details/failing_instances.out; else echo -e "${BOLD}[INFO]${RESET} All jobs are in running state\n"; echo -e "${BOLD}[INFO]${RESET} There are ${total_bosh_jobs} jobs in deployment ${BOSH_DEPLOYMENT}\n"; fi
}

function download_job_logs() {
  if [ -n "${extra_logs}" ]; then

  options_file="${tempdir}/bosh_job_details/bosh_job_file.out"
  if [ ! -f "$options_file" ]; then
	echo -e "${BOLD}[WARNING]${RESET} No jobs were found in deployment ${BOSH_DEPLOYMENT}...\n"
  else
echo -e "${BOLD}[INFO]${RESET} Flag '-X' used; will also collect AGENT and process logs\n"
  for node in `cat ${tempdir}/bosh_job_details/bosh_job_file.out`; do
	job=$(echo $node | sed 's/[/]/-/g')
	job_agent=$(echo ${node}-agent | sed 's/[/]/-/g')
	mkdir -p ${tempdir}/${job}
	mkdir -p ${tempdir}/${job_agent}
	echo -e "${BOLD}[INFO]${RESET} Capturing system stats for: ${BLUE_BOLD}${node}${RESET}\n"
	$bosh -d $BOSH_DEPLOYMENT ssh ${node} 'sudo su -c "mkdir -p /var/vcap/sys/log/diag; cp /var/vcap/monit/monit.log* /var/vcap/sys/log/diag; tar -zcf /var/vcap/sys/log/diag/root_log.tgz /var/vcap/data/root_log/; ps -eLo pid,tid,ppid,user:11,comm,state,wchan > /var/vcap/sys/log/diag/ps-elo-state.log; ps -auxwf > /var/vcap/sys/log/diag/ps-auxwf.log; ps -ef > /var/vcap/sys/log/diag/ps-ef.log; top -b -n 3 > /var/vcap/sys/log/diag/top-b-n-3.log; ifconfig > /var/vcap/sys/log/diag/ifconfig.log; free -h > /var/vcap/sys/log/diag/free.log; pstree -panl > /var/vcap/sys/log/diag/pstree-panl.log; vmstat -S M 1 3 > /var/vcap/sys/log/diag/vmstat.log; iostat -txm 1 3 > /var/vcap/sys/log/diag/iostat.log; df -h > /var/vcap/sys/log/diag/df.log; lsblk -a > /var/vcap/sys/log/diag/lsblk.log; lsof -nPi TCP > /var/vcap/sys/log/diag/tcp.log; netstat -ntlp > /var/vcap/sys/log/diag/netstat.log; iptables --list > /var/vcap/sys/log/diag/iptables.log; netstat -aW > /var/vcap/sys/log/diag/netstat-aw.log"' 2>/dev/null 
	echo -e "${BOLD}[INFO]${RESET} Downloading BOSH JOB logs for job: ${BLUE_BOLD}${node}${RESET}\n"
	$bosh logs ${node} --dir="${tempdir}/${job}"
	echo -e "${BOLD}[INFO]${RESET} Downloading BOSH AGENT logs for: ${BLUE_BOLD}${node}${RESET}\n"
	$bosh logs --agent ${node} --dir="${tempdir}/${job_agent}"
	echo -e "Cleaning up root_log / monit / and process files copied to job log dir (which are pulled along with 'bosh logs' command)\n"
	$bosh -d $BOSH_DEPLOYMENT ssh ${node} 'sudo su -c "rm -r /var/vcap/sys/log/diag/"'
  done
  fi

  else

  options_file="${tempdir}/bosh_job_details/bosh_job_file.out"
  if [ ! -f "$options_file" ]; then
  echo -e "${BOLD}[WARNING]${RESET} No jobs were found in deployment ${BOSH_DEPLOYMENT}...\n"
  else
  for node in `cat ${tempdir}/bosh_job_details/bosh_job_file.out`; do
        job=$(echo $node | sed 's/[/]/-/g')
        mkdir -p ${tempdir}/${job}
        echo -e "${BOLD}[INFO]${RESET}Downloading BOSH JOB logs for job: ${BLUE_BOLD}${node}${RESET}"
        $bosh logs ${node} --dir="${tempdir}/${job}"
  done
  fi
  fi

  pushd "${tempdir}" > /dev/null
    tar czf "${tempdir}/${datestring}-piv-support-logs.tar.gz" ./*
  popd > /dev/null
}

function output() {
  cp "${tempdir}/${datestring}-piv-support-logs.tar.gz" "${output_dir}/"
  echo -e "${BOLD}[INFO]${RESET} Logs saved to: ${output_dir}/${output_file}\n" 
  echo -e "${BOLD}[INFO]${RESET} File:${output_file} may be uploaded to:\n${BLUE}https://securefiles.pivotal.io/dropzone/customer-service/<ticket_number>${RESET}\n"
}

function cleanup() {
  echo -e "${BOLD}[INFO]${RESET}...cleaning up local files in tempdir: ${tempdir}\n"
  rm -r "${tempdir}"
}

options=($(bosh -d $BOSH_DEPLOYMENT instances --vitals --column=Instance | grep -v Instance | sed 's/[[:space:]]//g' | sed 's/\(.*\)/"\1"/g' | paste -s -d" ")) 

ERROR=" "
#Clear screen for menu
#clear


function ACTIONS {
printf "BOSH Jobs selected:\n"; msg=" nothing"
for i in ${!options[@]}; do
    [[ "${choices[i]}" ]] && { printf " %s\n" "${options[i]}"; msg=""; } | sed 's/"//g'  | tr -d " " >> ${tempdir}/bosh_job_details/bosh_job_file.out
    [[ "${choices[i]}" ]] && { printf " %s\n" "${options[i]}"; msg=""; } | sed 's/"//g'  | tr -d " "
done
download_job_logs
}

#Menu function
function MENU {
    echo -e "Jobs in deployment: ${GREEN}${BOSH_DEPLOYMENT}${RESET}"
    for NUM in ${!options[@]}; do
        echo "[""${choices[NUM]:- }""]" $(( NUM+1 ))") ${options[NUM]}"
    done    
    echo "$ERROR"
}

function LOOP {
while MENU && read -e -p "Select BOSH Job(s) using their number (again to uncheck, ENTER when done): " -n2 SELECTION && [[ -n "$SELECTION" ]]; do
    clear   
    if [[ "$SELECTION" == *[[:digit:]]* && $SELECTION -ge 1 && $SELECTION -le ${#options[@]} ]]; then
        (( SELECTION-- ))
        if [[ "${choices[SELECTION]}" == "+" ]]; then
            choices[SELECTION]=""
        else    
            choices[SELECTION]="+"
        fi      
            ERROR=" "
    else    
        ERROR="Invalid option: $SELECTION"
    fi
done
ACTIONS
}


function main() {
  while getopts "X" opt; do
    case $opt in
      X)
        extra_logs="true"
        ;;
      *)
        echo "Unknown arguments"
        usage
        ;;
    esac
  done

  tempdir=$(mktemp -d)
  mkdir -p ${tempdir}/bosh_job_details
  trap 'rm -rf ${tempdir:?nothing to remove}' INT TERM QUIT EXIT
  check_fast_fails
  get_vm_and_deployments_info
  LOOP
  output
  cleanup
}

main "${@:-}"
