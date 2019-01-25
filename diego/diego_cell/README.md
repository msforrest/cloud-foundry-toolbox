## diego_cell log collect scripts

diego-log-collect.sh 

### Usage: 

```
./cell_load.sh -X

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
	5. diego_cell:
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

  The output directory is your current working director: /home/ubuntu/mforrest/diego_cell/lab_diego_cell

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
```
