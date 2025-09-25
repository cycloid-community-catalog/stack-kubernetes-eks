#!/usr/bin/env bash

# Define colors for use in output messages
RED='\033[0;31m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
NC='\033[0m' # No Color

#
# Terraform
#

echo -e "${Yellow}Terraform version:${NC}"

LATEST_TERRAFORM_VERSION=$(curl -s 'https://hub.docker.com/v2/repositories/cycloid/terraform-resource/tags/?page_size=100' | \
  jq -r '.results[].name' | \
  grep '^1\.' | \
  sort -V | \
  tail -n 1)

echo -e "${Blue}    Latest cycloid/terraform-resource available:${NC} $LATEST_TERRAFORM_VERSION"


#
# Providers
#

# Generate lock file to get the provider version
LOCKFILE=".terraform.lock.hcl"
rm $LOCKFILE -rf
cp main.tf.sample main.tf
terraform init >/dev/null


terraform providers lock >/dev/null

echo -e "${Yellow}Providers versions:${NC}"
# Extract providers and pinned versions
grep -A1 '^provider ' "$LOCKFILE" | \
awk '
  /^provider/ {
    gsub(/"/,""); gsub(/{/,"");
    provider=$2
  }
  /version/ {
    gsub(/"/,""); pinned=$3
    print provider, pinned
  }
' | while read -r provider version; do
  # Split into namespace/name
  namespace=$(echo "$provider" | cut -d'/' -f2)
  name=$(echo "$provider" | cut -d'/' -f3)

  # Query registry for latest version
  latest=$(curl -s "https://registry.terraform.io/v1/providers/${namespace}/${name}" \
           | jq -r '.version')


  if [ "$version" != "$latest" ]; then
    echo -e "${RED}    provider $provider: $version vs $latest ${NC}"
  else
    echo -e "${NC}    provider $provider: $version vs $latest ${NC}"
  fi
done

#
# Modules
#
echo -e "${Yellow}Modules versions:${NC}"
# Get modules with versions from terraform CLI
terraform modules -json | jq -r '.modules[] | select(.version != "") | [.source, .version] | @tsv' |
while IFS=$'\t' read -r source version; do
  # Only check registry sources
  if [[ "$source" =~ registry.terraform.io/(.*) ]]; then
    module_name="${BASH_REMATCH[1]}"

    # Query Terraform registry for latest version
    latest=$(curl -s "https://registry.terraform.io/v1/modules/${module_name}" | jq -r '.version')

    if [ "$version" != "$latest" ]; then
      echo -e "${RED}    provider $module_name: $version vs $latest ${NC}"
    else
      echo -e "${NC}    provider $module_name: $version vs $latest ${NC}"
    fi
  else
    echo "$source $version (local or unsupported source)"
  fi
done

# clean sample
rm main.tf