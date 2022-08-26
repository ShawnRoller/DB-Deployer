#!/bin/bash

#  DeployScript.sh
#  DB Deployer
#
#  Created by Shawn Roller on 5/1/19.
#  Copyright © 2019 Shawn Roller. All rights reserved.
echo "*********************************"
echo "Beginning deploy to ${2}"
echo "*********************************"
IFS=$'\n'
files=$(ls -v1 "${3}"/*.sql)

for file in $files
do
    echo executing $file
    if [ "$7" = "true" ]
        then
            echo "********* DEBUG *********"
            echo "${6}"/sqlcmd -S "${4}" -d "${5}" -i $file
            echo "********* END DEBUG *********"
    fi
    "${6}"/sqlcmd -S "${4}" -d "${5}" -i $file
    command
done

echo "*********************************"
echo "Deploys complete"
echo "*********************************"
