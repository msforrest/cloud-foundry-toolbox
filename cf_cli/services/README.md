## cloud-foundry-toolbox

#### BOSH log collect script - generic menu based cf-log-collect

##### Usage:
_./cf-redis-service-list_v1.sh_

cf-redis-service-list_v1.sh will obtain all Service Instances (SI)'s that have been
created by a redis service broker and list the associated service broker,
service plan, Service Instance (SI) name, # of bound apps and app names (if any)
age of each Service Instance (SI), and the ORG/Space to which they belong

requires: jq, cf cli, bc

##### example output:

Service     Service_Plan     Service_Name     #_bound_apps     Bound Application(s)     Organization     Space     Age_In_Days
-------     ------------     ------------     ------------     --------------------     ------------     -----     -----------
p-redis     shared-vm        redis-for-kafka  0                                         klahti           test      3
p-redis     shared-vm        testlog          0                                         test             test      2
p.redis     cache-large      redis-test       2                test-app                 mforrest          redis     14
                                                               cf-nodejs                mforrest          redis     14
