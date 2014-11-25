#!/bin/bash

# bre (build and release engineer) script that does
# the tiresome task of creating release documentation
# in the chili-ticket-system

# this is a draft, it has to be extended in the future

echo YOU DID NOT EDIT bre.sh and configured essential stuff
exit
username=
password=
server=https://host.with.redmine.or.chili
project_id=name_of_project

repository=${server}/projects/${project_id}

# custom query defined for the project or globaly
release_ticket_url=${repository}/issues?query_id=11

source ./chili.sh

cd $(dirname $0)
ci_path=$(pwd)
base_version=$(cat BASE_VERSION)
release_id=$(cat RELEASE_ID)

echo YOU DID NOT CONFIGURE THE BRE TASKS
exit
pushd ${workspaces}
auto_version=$(git log --oneline | grep -v '[a-z0-9*] auto:' | wc | awk '{print $1}')
auto_version=$(printf "%06d" ${auto_version})
auto_version=${base_version}-${release_id}a${auto_version}c${git_short_hash}
popd

chili_login

echo "Release ${auto_version}" > bre_ticket_text
chili_get_tickets ${release_ticket_url} |sed 's|^\([^ ]*\) |\1 \#|' | sed 's|^| \n * |' >> bre_ticket_text
bre_ticket_id=$(chili_create_ticket "BRE Release ${auto_version}" "$(cat bre_ticket_text)")
rm bre_ticket_text
chili_comment_ticket ${bre_ticket_id} "bre comment"
chili_change_ticket_state ${bre_ticket_id} "Approved"
chili_change_ticket_state ${bre_ticket_id} "In Progress"

merge_cmd=$(chili_get_tickets ${release_ticket_url} | awk '{print $2}' | xargs -iX echo 'git merge "#X"')

pushd path/to/git

echo 'git checkout master'
echo "${merge_cmd}"
# setup files required for build

chili_comment_ticket ${bre_ticket_id} "merge complete"


pushd tdd
echo './release-test.sh'
chili_comment_ticket ${bre_ticket_id} "tdd testresults"
popd

pushd bdd
echo './release-test-bdd.sh'
chili_comment_ticket ${bre_ticket_id} "bdd testresults"
popd

chili_comment_ticket ${bre_ticket_id} "tests complete"

pushd package
# win32: make msi from zip (as parameter) zip contains filelist
echo make derived-files

chili_change_ticket_state ${bre_ticket_id} "Release"

popd
# VERSION
# changelog

echo 'git tag $(cat VERSION); git push --tags'

pushd package
# copies to tmp / triggers remote copy only
# process should not require to change git again
echo make
popd
chili_comment_ticket ${bre_ticket_id} "build complete"

# packages are now ready, deploy them in vm's
pushd package
# installs on a clean vm, runs complete set of bdd tests on the installation
# sends reports
echo make deploy-test-vm
popd

chili_comment_ticket ${bre_ticket_id} "package tests complete"


popd

chili_change_ticket_state ${bre_ticket_id} "Closed"
