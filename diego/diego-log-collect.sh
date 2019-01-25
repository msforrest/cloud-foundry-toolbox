#!/bin/bash
set -eu

set -o pipefail

extra_logs=""
cell_load_min=""
datestring="$(date +%Y-%m-%d-%H-%M-%S)"
output_dir=$(pwd)
output_file="${datestring}-piv-support-logs.tar.gz"
bosh=`which bosh`

function usage(){
  >&2 echo "Usage: 

  "Ex: ./cell_load.sh -X"

  -X (Optional) Include diego_cell process and BOSH Agent logs

  This program will find all diego_cells with load above specified threshold
  and pull down the following files for those cells:
	1. BOSH JOB logs for diego_cells with high load
	2. bosh instances --details
	3. bosh vms --vitals 
	4. bosh deployments list
  
  If using -X flag the following logs will also be collected:
	1. diego_cell BOSH Agent logs which have high load
	2. diego_cell /var/vcap/data/root_log/* (sysstat/kernel logs..etc)
	3. diego_cell /var/vcap/monit/monit.log
	4. diego_database BOSH JOB logs
	5. top/vmstat/lsof and other process info 

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
  set +u
  if [ -z "${BOSH_ENVIRONMENT}" ] || [ -z "${BOSH_CLIENT_SECRET}" ] || [ -z "${BOSH_CLIENT}" ] || [ -z "${BOSH_CA_CERT}" ] || [ -z "${BOSH_DEPLOYMENT}" ] ; then
    echo "BOSH_DEPLOYMENT, BOSH_ENVIRONMENT, BOSH_CLIENT_SECRET, BOSH_CLIENT, and BOSH_CA_CERT are required environment variables"
    usage
  fi
  set -u
}

GREEN="\033[0;32m"
GREEN_BOLD="\033[1;32m"
BLUE="\033[0;34m"
BLUE_BOLD="\033[1;34m"
BOLD="\033[1m"
RESET="\033[0m"

function get_vm_and_deployments_info() {
  echo -e "${BOLD}[INFO]${RESET}Retrieving deployment and job info..."
  echo -e " - collecting 'bosh deployment'"
  $bosh --tty deployments &> "${tempdir}/bosh_job_details/deployments"
  echo -e " - collecting 'bosh instance --details'"
  $bosh --tty instances --details &> "${tempdir}/bosh_job_details/instances.details"
  echo -e " - collecting 'bosh vms --vitals'\n"
  $bosh --tty vms --vitals &> "${tempdir}/bosh_job_details/vms.vitals"
}

function convert_to_integer () {
  echo "$@" | awk -F "." '{ printf("%02d%02d\n", $1,$2); }';
}

function download_diego_logs() {
	echo -e "${GREEN}Temporary Directory: ${RESET}${tempdir}\n"
	echo -e "${BOLD}[INFO]${RESET} Collecting load info from diego_cell VMs with ${BLUE_BOLD}load[1m]${RESET} higher than ${BLUE_BOLD}${cell_load_min}${RESET}..."

  $bosh -d $BOSH_DEPLOYMENT instances --vitals --column=Instance --column=load_1m_5m_15m | grep -E 'diego_cell|diego_database'  > ${tempdir}/bosh_job_details/diego_load_file.out
  for load in `cat ${tempdir}/bosh_job_details/diego_load_file.out | grep diego_cell | awk '{print $2}' | tr -d ','| grep -v "0.00"`; do
	if [ "$(convert_to_integer $load)" -ge "$(convert_to_integer $cell_load_min)" ]
	then
		echo "$load >= $cell_load_min"
		cat ${tempdir}/bosh_job_details/diego_load_file.out | grep $load | grep diego_cell | awk '{print $1}'  >> ${tempdir}/bosh_job_details/node_diego_cell.out
	fi
  done

#  mkdir -p ${tempdir}/bosh_job_details
#  cp ${tempdir}/* ${tempdir}/bosh_job_details
  total_diego_cells=$(cat ${tempdir}/bosh_job_details/node_diego_cell.out | wc -l) 
  echo -e "${BOLD}[INFO]${RESET} There are $total_diego_cells diego_cells with load above ${cell_load_min}\n" 

  if [ -n "${extra_logs}" ]; then

  file="${tempdir}/bosh_job_details/node_diego_cell.out"
  if [ ! -f "$file" ]; then
	echo -e "${BOLD}[WARNING]${RESET} No diego_cell has load greater than entered value of: ${BLUE}${cell_load_min}${RESET}...\n"
  else
  for node in `cat ${tempdir}/bosh_job_details/node_diego_cell.out`; do
	cell=$(echo $node | sed 's/[/]/-/g')
	cell_agent=$(echo ${node}-agent | sed 's/[/]/-/g')
	mkdir -p ${tempdir}/${cell}
	mkdir -p ${tempdir}/${cell_agent}
	echo -e "${BOLD}[INFO]${RESET} Capturing system stats for: ${BLUE_BOLD}${node}${RESET}\n"
	$bosh -d $BOSH_DEPLOYMENT ssh ${node} 'sudo su -c "mkdir -p /var/vcap/sys/log/diag; cp /var/vcap/monit/monit.log* /var/vcap/sys/log/diag; tar -zcf /var/vcap/sys/log/diag/root_log.tgz /var/vcap/data/root_log/; ps -eLo pid,tid,ppid,user:11,comm,state,wchan > /var/vcap/sys/log/diag/ps-elo-state.log; ps -auxwf > /var/vcap/sys/log/diag/ps-auxwf.log; ps -ef > /var/vcap/sys/log/diag/ps-ef.log; top -b -n 3 > /var/vcap/sys/log/diag/top-b-n-3.log; ifconfig > /var/vcap/sys/log/diag/ifconfig.log; free -h > /var/vcap/sys/log/diag/free.log; pstree -panl > /var/vcap/sys/log/diag/pstree-panl.log; vmstat -S M 1 3 > /var/vcap/sys/log/diag/vmstat.log; iostat -txm 1 3 > /var/vcap/sys/log/diag/iostat.log; df -h > /var/vcap/sys/log/diag/df.log; lsblk -a > /var/vcap/sys/log/diag/lsblk.log; lsof -nPi TCP > /var/vcap/sys/log/diag/tcp.log; netstat -ntlp > /var/vcap/sys/log/diag/netstat.log; iptables --list > /var/vcap/sys/log/diag/iptables.log; netstat -aW > /var/vcap/sys/log/diag/netstat-aw.log"' 2>/dev/null 
	echo -e "${BOLD}[INFO]${RESET} Downloading BOSH JOB logs for diego_cell: ${BLUE_BOLD}${node}${RESET}\n"
	$bosh logs ${node} --dir="${tempdir}/${cell}"
	echo -e "${BOLD}[INFO]${RESET} Downloading BOSH AGENT logs for: ${BLUE_BOLD}${node}${RESET}\n"
	echo "--------- dir: ${tempdir}/${cell_agent}"
	$bosh logs --agent ${node} --dir="${tempdir}/${cell_agent}"
	echo -e "Cleaning up root_log / monit / and process files copied to job log dir (which are pulled along with 'bosh logs' command)\n"
	$bosh -d $BOSH_DEPLOYMENT ssh ${node} 'sudo su -c "rm -r /var/vcap/sys/log/diag/"'
  done

  for node in `cat ${tempdir}/bosh_job_details/diego_load_file.out | grep diego_database | awk '{print $1}'`; do
	diego_db=$(echo $node | sed 's/[/]/-/g')
	mkdir -p ${tempdir}/${diego_db}
	echo -e "${BOLD}[INFO]${RESET} Downloading BOSH JOB logs for: ${BLUE_BOLD}${node}${RESET}"
	$bosh logs ${node} --dir="${tempdir}/${diego_db}"
  done
  fi

  else

  file="${tempdir}/bosh_job_details/node_diego_cell.out"
  if [ ! -f "$file" ]; then
  echo -e "${BOLD}[WARNING]${RESET} No diego_cell has load >= entered value of: ${GREEN_BOLD}${cell_load_min}${RESET}...\n"
  else
  for node in `cat ${tempdir}/bosh_job_details/node_diego_cell.out`; do
        cell=$(echo $node | sed 's/[/]/-/g')
        cell_agent=$(echo agent-$node | sed 's/[/]/-/g')
        mkdir -p ${tempdir}/${cell}
        echo -e "${BOLD}[INFO]${RESET}Downloading BOSH JOB logs for diego_cell: ${BLUE_BOLD}${node}${RESET}"
        $bosh logs ${node} --dir="${tempdir}/${cell}"
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

  echo -e "\033[1;34mEnter diego_cell load threshold:\033[0m"
  read cell_load_min

  get_vm_and_deployments_info
  download_diego_logs
  output
  cleanup
}

main "${@:-}"
