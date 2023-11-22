#!/bin/bash

# Define colors for use in output messages
RED='\033[0;31m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
NC='\033[0m' # No Color

if [ $# -eq 0 ]; then
  FILES=$(ls */helm.tf)
else
  FILES=$1
fi

# make sure local repo updated
helm repo update
# Loop through each file in the current directory ending with "helm.tf"

# helm repo rm  $(helm repo list | awk '{print $1}' | grep -v NAME)
for helm in $FILES;do
  echo -e "${Blue}$helm"
  helm_path=$(echo $helm | sed -E 's/[^\/]+$//')
  repository=$(grep -E "^[ ]+repository[^=]+=" $helm | awk '{print $3}' | sed 's/"//g')
  chart=$(grep -E "^[ ]+chart[^=]+=" $helm | awk '{print $3}' | sed 's/"//g')
  version=$(grep -E "^[ ]+version[^=]+=" $helm | awk '{print $3}' | sed 's/"//g')
  values_path=$(grep -E "#VALUES: " $helm | awk '{print $2}')
  local_values=$(grep -E "file.*values([-_]?.*)?.yaml" $helm | sed 's/.*\///;s/\.yaml.*/\.yaml/')

  # Print the chart details
  echo -e "${Yellow}  Chart:${NC} $chart"
  echo -e "${Yellow}  Repository:${NC} $repository"
  echo -e "${Yellow}  Installed version:${NC} $version"

  # Add the chart repository and get the latest version of the chart from the repository
  helm repo add $chart $repository > /dev/null 2>&1
  latest_version=$(helm search repo --regexp "\v$chart/$chart\v" -o json 2> /dev/null| jq -r '.[].version' | sed 's/v//')
  echo -e "${Yellow}  Upstream version:${NC} $latest_version"

  # Check if the installed version is the latest version, and if not, print a warning message
  Yellow='\033[0;33m'
  if [ "$version" != "$latest_version" ]; then
      echo -e "${RED}  [Need to be updated]${NC}"
      
      # Download the latest values file for the chart from the given URL
      echo "  wget $values_path -O /tmp/values-$chart.yaml"
      echo "  meld $helm_path$local_values /tmp/values-$chart.yaml"
      echo "  vim $helm"
  fi
  echo ""
done
