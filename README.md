## BOSH log collect scripts



**_cf-log-collect.sh_** 

##### Usage: 

```
Usage: 

  Ex: ./cf-log-collect.sh -X

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

  Jobs in deployment: cf-b8a0cd3a767cd0eeca66
	[ ] 1) clock_global/83246a6a-fcc4-4a79-b0ff-1582eb90da7c
	[ ] 2) cloud_controller/6ff71454-8b04-45d0-a94f-160e3a2fc4e8
	[*] 3) cloud_controller_worker/bf10105a-6850-443c-ad99-d886cf2e3afc
	[ ] 4) consul_server/a9ba1509-3a6e-4b8a-bdd6-49986133697b
	[ ] 5) credhub/4e4f2d6a-0da4-4f87-bab1-c80d03bc8e83
	[*] 6) diego_brain/09131c43-f438-4fb0-a8ed-68d6821d46fd
	[*] 7) diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
	[*] 8) diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
	[*] 9) diego_cell/ce6a04ea-33f1-4e01-9ed6-f42470242ed7
	[ ] 10) diego_database/f16a141f-7907-4373-a3cd-d72e7dd874d3
	[ ] 11) doppler/585b5943-51d8-4421-8d64-533986648bed
	[ ] 12) ha_proxy/b10ce83d-4116-41b0-9dd0-3be0981b3cbc
	[ ] 13) loggregator_trafficcontroller/51f936c8-0062-4f8e-84f3-5152680b284d
	[ ] 14) mysql/0079a88c-e317-440a-bf4e-01c28b01b152
	[ ] 15) mysql/15b595eb-7c9d-42ff-bb45-025ac47f4726
	[ ] 16) mysql/e4dfcbcb-8943-43ee-a7a2-025df2b4f0c0
	[ ] 17) mysql_monitor/e977aab8-0c96-4cc4-9071-a94010c1430f
	[ ] 18) mysql_proxy/792df664-5e7d-45e5-a36a-ca6567e41da9
	[ ] 19) mysql_proxy/8015a342-fa9f-4f89-8dcf-70d1fee78fa7
	[ ] 20) nats/0f6844f1-c458-4379-8a3e-696fc9321898
	[ ] 21) nfs_server/6ddb3b9a-6a45-495a-84c6-544fb6bc5487
	[ ] 22) router/adcdb4c1-a95e-4110-831c-1d6d94090a6b
	[ ] 23) service-discovery-controller/a364811a-df3f-4a95-ae89-52f431cf78e5
	[ ] 24) syslog_adapter/3b1111ce-e037-47eb-814e-ea0a12d9fbc6
	[ ] 25) syslog_scheduler/b17adc08-9bad-4e19-991a-980666e2322f
	[ ] 26) tcp_router/fdaed2e4-d5f2-444e-808e-1a8a96db96e8
	[ ] 27) uaa/09c15325-cd2f-4311-bc8b-3824ca7d21bd

	Select BOSH Job(s) using their number (again to uncheck, ENTER when done): 
	BOSH Jobs selected:
		cloud_controller_worker/bf10105a-6850-443c-ad99-d886cf2e3afc
		diego_brain/09131c43-f438-4fb0-a8ed-68d6821d46fd
		diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
		diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
		diego_cell/ce6a04ea-33f1-4e01-9ed6-f42470242ed7

```
##### Example:

```
$ ./cf-log-collect.sh 

Temporary Directory: /tmp/tmp.JJ08ryfdfV

[INFO] Retrieving deployment and job info for deployment: cf-b8a0cd3a767cd0eeca66...
 - collecting 'bosh deployment'
 - collecting 'bosh instance --details'
 - collecting 'bosh vms --vitals'

[INFO] All jobs are in running state

[INFO] There are 27 jobs in deployment cf-b8a0cd3a767cd0eeca66

Jobs in deployment: cf-b8a0cd3a767cd0eeca66
        [ ] 1) clock_global/83246a6a-fcc4-4a79-b0ff-1582eb90da7c
        [ ] 2) cloud_controller/6ff71454-8b04-45d0-a94f-160e3a2fc4e8
        [*] 3) cloud_controller_worker/bf10105a-6850-443c-ad99-d886cf2e3afc
        [ ] 4) consul_server/a9ba1509-3a6e-4b8a-bdd6-49986133697b
        [ ] 5) credhub/4e4f2d6a-0da4-4f87-bab1-c80d03bc8e83
        [*] 6) diego_brain/09131c43-f438-4fb0-a8ed-68d6821d46fd
        [*] 7) diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
        [*] 8) diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
        [*] 9) diego_cell/ce6a04ea-33f1-4e01-9ed6-f42470242ed7
        [ ] 10) diego_database/f16a141f-7907-4373-a3cd-d72e7dd874d3
        [ ] 11) doppler/585b5943-51d8-4421-8d64-533986648bed
        [ ] 12) ha_proxy/b10ce83d-4116-41b0-9dd0-3be0981b3cbc
        [ ] 13) loggregator_trafficcontroller/51f936c8-0062-4f8e-84f3-5152680b284d
        [ ] 14) mysql/0079a88c-e317-440a-bf4e-01c28b01b152
        [ ] 15) mysql/15b595eb-7c9d-42ff-bb45-025ac47f4726
        [ ] 16) mysql/e4dfcbcb-8943-43ee-a7a2-025df2b4f0c0
        [ ] 17) mysql_monitor/e977aab8-0c96-4cc4-9071-a94010c1430f
        [ ] 18) mysql_proxy/792df664-5e7d-45e5-a36a-ca6567e41da9
        [ ] 19) mysql_proxy/8015a342-fa9f-4f89-8dcf-70d1fee78fa7
        [ ] 20) nats/0f6844f1-c458-4379-8a3e-696fc9321898
        [ ] 21) nfs_server/6ddb3b9a-6a45-495a-84c6-544fb6bc5487
        [ ] 22) router/adcdb4c1-a95e-4110-831c-1d6d94090a6b
        [ ] 23) service-discovery-controller/a364811a-df3f-4a95-ae89-52f431cf78e5
        [ ] 24) syslog_adapter/3b1111ce-e037-47eb-814e-ea0a12d9fbc6
        [ ] 25) syslog_scheduler/b17adc08-9bad-4e19-991a-980666e2322f
        [ ] 26) tcp_router/fdaed2e4-d5f2-444e-808e-1a8a96db96e8
        [ ] 27) uaa/09c15325-cd2f-4311-bc8b-3824ca7d21bd
Select BOSH Job(s) using their number (again to uncheck, ENTER when done):
	BOSH Jobs selected:
	cloud_controller_worker/bf10105a-6850-443c-ad99-d886cf2e3afc
	diego_brain/09131c43-f438-4fb0-a8ed-68d6821d46fd
	diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
	diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
	diego_cell/ce6a04ea-33f1-4e01-9ed6-f42470242ed7
	diego_database/f16a141f-7907-4373-a3cd-d72e7dd874d3

[INFO] Capturing system stats for: diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
[INFO] Flag '-X' used; will also collect AGENT and process logs

[INFO] Capturing system stats for: cloud_controller_worker/bf10105a-6850-443c-ad99-d886cf2e3afc
Succeeded
[INFO] Downloading BOSH JOB logs for job: cloud_controller_worker/bf10105a-6850-443c-ad99-d886cf2e3afc
Succeeded
[INFO] Downloading BOSH AGENT logs for: cloud_controller_worker/bf10105a-6850-443c-ad99-d886cf2e3afc
Succeeded
[INFO] Capturing system stats for: diego_brain/09131c43-f438-4fb0-a8ed-68d6821d46fd
Succeeded
[INFO] Downloading BOSH JOB logs for job: diego_brain/09131c43-f438-4fb0-a8ed-68d6821d46fd
Succeeded
[INFO] Downloading BOSH AGENT logs for: diego_brain/09131c43-f438-4fb0-a8ed-68d6821d46fd
Succeeded
[INFO] Capturing system stats for: diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
Succeeded
[INFO] Downloading BOSH JOB logs for job: diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
Succeeded
[INFO] Downloading BOSH AGENT logs for: diego_cell/0ee6797d-934c-4fb1-9e16-e183b8e22e78
Succeeded
[INFO] Capturing system stats for: diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
Succeeded
[INFO] Downloading BOSH JOB logs for job: diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
Succeeded
[INFO] Downloading BOSH AGENT logs for: diego_cell/2dd25c9c-72f0-40a4-9ac7-23687084ca5f
Succeeded
[INFO] Capturing system stats for: diego_cell/ce6a04ea-33f1-4e01-9ed6-f42470242ed7
Succeeded
[INFO] Downloading BOSH JOB logs for job: diego_cell/ce6a04ea-33f1-4e01-9ed6-f42470242ed7
Succeeded
[INFO] Downloading BOSH AGENT logs for: diego_cell/ce6a04ea-33f1-4e01-9ed6-f42470242ed7
Succeeded
[INFO] Capturing system stats for: diego_database/f16a141f-7907-4373-a3cd-d72e7dd874d3
Succeeded
[INFO] Downloading BOSH JOB logs for job: diego_database/f16a141f-7907-4373-a3cd-d72e7dd874d3
Succeeded
[INFO] Downloading BOSH AGENT logs for: diego_database/f16a141f-7907-4373-a3cd-d72e7dd874d3
Succeeded
[INFO] Logs saved to: /home/ubuntu/mforrest/diego_cell/lab_diego_cell/2019-01-29-17-46-36-piv-support-logs.tar.gz

[INFO] File:2019-01-29-17-46-36-piv-support-logs.tar.gz may be uploaded to:
https://securefiles.pivotal.io/dropzone/customer-service/<ticket_number>

[INFO]...cleaning up local files in tempdir: /tmp/tmp.JJ08ryfdfV
```
