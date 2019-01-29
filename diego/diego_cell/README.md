## diego_cell log collect scripts



**_diego-log-collect.sh_** 

##### Usage: 

```
./diego-log-collect.sh -X

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

  The output directory is your current working directory: /home/ubuntu/mforrest/diego_cell/lab_diego_cell

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
##### Example:

```
$ ./diego-log-collect.sh -X

Enter diego_cell load threshold (ex. 8.00):
5.00

[INFO]Retrieving deployment and job info...
 - collecting 'bosh deployment'
 - collecting 'bosh instance --details'
 - collecting 'bosh vms --vitals'

Temporary Directory: /tmp/tmp.yoidfFBRnx

[INFO] Collecting load info from diego_cell VMs with load[1m] higher than 5...
8.39 >= 5.00
5.17 >= 5.00

[INFO] There are 2 diego_cell with load above 5

[INFO] Capturing system stats for: diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
Using environment '10.193.78.11' as user 'admin' (bosh.*.read, openid, bosh.*.admin, bosh.read, bosh.admin)
Using deployment 'cf-b8a0cd3a767cd0eeca66'

[INFO] Downloading BOSH JOB logs for diego_cell: diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
Task 34713 | 22:58:01 | Fetching logs for diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78 (1): Finding and packing log files (00:00:05)
Downloading resource 'e6dc925c-c8a4-4080-5ce6-43b71710a3fd' to '/tmp/tmp.yoidfFBRnx/diego_cell-0ee6797d-934c-4fb1-9e16-e183b8e22e78/cf-b8a0cd3a767cd0eeca66.diego_cell.0ee6797d-934c-4fb1-9e16-e183b8e22e78-20190124-225806-566698636.tgz'...
Succeeded

[INFO] Downloading BOSH AGENT logs for: diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
Using environment '10.193.78.11' as user 'admin' (bosh.*.read, openid, bosh.*.admin, bosh.read, bosh.admin)
Using deployment 'cf-b8a0cd3a767cd0eeca66'
Task 34714 | 22:58:09 | Fetching logs for diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78 (1): Finding and packing log files (00:00:01)
Downloading resource '1312c907-e454-4978-7bf9-db239a8f8d0e' to '/tmp/tmp.yoidfFBRnx/agent-diego_cell-0ee6797d-934c-4fb1-9e16-e183b8e22e78/cf-b8a0cd3a767cd0eeca66.diego_cell.0ee6797d-934c-4fb1-9e16-e183b8e22e78-20190124-225810-892956273.tgz'...
Succeeded
Cleaning up root_log / monit / and process files copied to job log dir (which are pulled along with 'bosh logs' command)

[INFO] Capturing system stats for: diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f

[INFO] Downloading BOSH JOB logs for diego_cell: diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
Task 34719 | 22:58:15 | Fetching logs for diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f (2): Finding and packing log files (00:00:03)
Downloading resource 'a96ef1e8-008e-4c39-7133-103112664ca7' to '/tmp/tmp.yoidfFBRnx/diego_cell-2dd25c9c-72f0-40a4-9ac7-23687084ca5f/cf-b8a0cd3a767cd0eeca66.diego_cell.2dd25c9c-72f0-40a4-9ac7-23687084ca5f-20190124-225818-32315849.tgz'...
Succeeded

[INFO] Downloading BOSH AGENT logs for: diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
Task 34720 | 22:58:20 | Fetching logs for diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f (2): Finding and packing log files (00:00:01)
Downloading resource '2b102e72-e57f-48b6-4395-5266e3819546' to '/tmp/tmp.yoidfFBRnx/agent-diego_cell-2dd25c9c-72f0-40a4-9ac7-23687084ca5f/cf-b8a0cd3a767cd0eeca66.diego_cell.2dd25c9c-72f0-40a4-9ac7-23687084ca5f-20190124-225821-915974203.tgz'...
Succeeded
Cleaning up root_log / monit / and process files copied to job log dir (which are pulled along with 'bosh logs' command)
Succeeded

[INFO] Downloading BOSH JOB logs for: diego_database/f16a141f-7907-4373-a3cd-d72e7dd874d3
Task 34729 | 22:58:40 | Fetching logs for diego_database/f16a141f-7907-4373-a3cd-d72e7dd874d3 (0): Finding and packing log files (00:00:03)
Downloading resource '4ce58953-c635-4211-6977-f2ad31b6d9a6' to '/tmp/tmp.yoidfFBRnx/diego_database-f16a141f-7907-4373-a3cd-d72e7dd874d3/cf-b8a0cd3a767cd0eeca66.diego_database.f16a141f-7907-4373-a3cd-d72e7dd874d3-20190124-225843-726597334.tgz'...
Succeeded

[INFO] Logs saved to: /home/ubuntu/mforrest/diego_cell/lab_diego_cell/2019-01-24-22-57-49-piv-support-logs.tar.gz

[INFO] File:2019-01-24-22-57-49-piv-support-logs.tar.gz may be uploaded to:
https://securefiles.pivotal.io/dropzone/customer-service/<ticket_number>

[INFO]...cleaning up local files in tempdir: /tmp/tmp.yoidfFBRnx
```
