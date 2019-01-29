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

  This program will obtain the following for all selected bosh instances:
	1. BOSH JOB logs
	2. bosh instances --details
	3. bosh vms --vitals 
	4. bosh deployments list
  
  If using -X flag the following logs will also be collected for each selected instance:
	1. BOSH Agent logs
	2. /var/vcap/data/root_log/* (sysstat/kernel logs..etc)
	3. /var/vcap/monit/monit.log
	4. Instance:
		- ps -eLo pid,tid,ppid,user:11,comm,state,wchan
		- ps auxwf
		- pstree -panl
		- ifconfig
		- free -h
		- vmstat -S M 1 3
		- iostat -txm 1 3
		- netstat -ntlp
		- netstat -aW
		- lsblk -a g
		- df -h
		- iptables --list

  The output directory is your current working director: ${output_dir}

  This tool requires the bosh v2 cli and the following environment variables to be set:
	BOSH_ENVIRONMENT
	BOSH_CLIENT_SECRET
	BOSH_CLIENT
	BOSH_CA_CERT
	BOSH_DEPLOYMENT

  Optionally if you require communicating with your BOSH director through a gateway, you must set:
	BOSH_GW_PRIVATE_KEY
	BOSH_GW_USER
	BOSH_GW_HOST
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
