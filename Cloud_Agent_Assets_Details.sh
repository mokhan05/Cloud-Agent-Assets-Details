#!/bin/bash

# d=$(date -d "yesterday" +%F)
d=$(date +%F)
tcount=""

read -p "Enter the API server URL e.g qualysapi.qg2.apps.qualys.com: " pod
read -p "Enter username: " usr
read -s -p "Enter password: " pass
echo ""

getcount(){
echo    "<ServiceRequest>
 <filters>
 <Criteria field=\"lastCheckedIn\" operator=\"LESSER\">$d</Criteria>
 </filters>
</ServiceRequest>" > /tmp/list_all_agents.xml
count=$(curl -s -u "$usr:$pass" -X "POST" -H "Content-Type: text/xml" -H "Cache-Control: no-cache" --data-binary @list_all_agents.xml "https://$pod/qps/rest/2.0/count/am/hostasset")
tcount=$(echo $count | grep -oP "(?<=<count>).*(?=</count>)")
}

getdata(){
echo    "<ServiceRequest>
 <preferences>
 <limitResults>$tcount</limitResults>
 </preferences>
 <filters>
 <Criteria field=\"lastCheckedIn\" operator=\"LESSER\">$d</Criteria>
 </filters>
</ServiceRequest>" > /tmp/list_all_agents.xml
curl -s -u "$usr:$pass" -X "POST" -H "Content-Type: text/xml" -H "Cache-Control: no-cache" --data-binary @list_all_agents.xml "https://$pod/qps/rest/2.0/search/am/hostasset/" > /tmp/temp
}

getcount
getdata

echo -e "\n\nFollowing is the list of assets which are not communicating to platform\n"
echo "hostName|platform|activatedModule|agentVersion|status"
#assetId=($(grep -oP '(?<=assetId>)[^<]+' "/tmp/temp"))
fqdn=($(grep -oP '(?<=fqdn>)[^<]+' "/tmp/temp"))
activatedModule=($(grep -oP '(?<=activatedModule>)[^<]+' "/tmp/temp"))
#lastUpdated=($(grep -oP '(?<=lastUpdated>)[^<]+' "/tmp/temp"))
#state=($(grep -oP '(?<=state>)[^<]+' "/tmp/temp"))
#address=($(grep -oP '(?<=address>)[^<]+' "/tmp/temp"))
#lastComplianceScan=($(grep -oP '(?<=lastComplianceScan>)[^<]+' "/tmp/temp"))
agentVersion=($(grep -oP '(?<=agentVersion>)[^<]+' "/tmp/temp"))
status=($(grep -oP '(?<=status>)[^<]+' "/tmp/temp"))
#lastCheckedIn=($(grep -oP '(?<=lastCheckedIn>)[^<]+' "/tmp/temp"))
platform=($(grep -oP '(?<=platform>)[^<]+' "/tmp/temp"))

for i in ${!fqdn[*]}
do
  echo "${fqdn[$i]}|${platform[$i]}|\"${activatedModule[$i]}\"|${agentVersion[$i]}|${status[$i]}" | grep "STATUS_INACTIVE"
  echo "${fqdn[$i]},${platform[$i]},\"${activatedModule[$i]}\",${agentVersion[$i]},${status[$i]}" >> /tmp/d1
done

echo "hostName,platform,activatedModule,agentVersion,status" > inactive_assets_list.csv
cat /tmp/d1 | grep "STATUS_INACTIVE" >> inactive_assets_list.csv
echo -e "\nList of assets not communicating with platform is created under inactive_assets_list.csv"

rm -rf /tmp/list_all_agents.xml /tmp/temp /tmp/d1