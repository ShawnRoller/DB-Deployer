#!/bin/sh

#  DeployScript.sh
#  DB Deployer
#
#  Created by Shawn Roller on 5/1/19.
#  Copyright © 2019 Shawn Roller. All rights reserved.
echo "*********************************"
echo "Beginning deploy to ${2}"
echo "*********************************"

files=$(ls -v1 "${3}"/*.sql)

for file in $files
do
    echo executing $file
    sqlcmd -S "${4}" -d "${5}" -i $file
done

echo "*********************************"
echo "Deploys complete"
echo "*********************************"
