#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : linux_apply_cookbook.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2016-05-27 17:35:35>
##-------------------------------------------------------------------
################################################################################################
. /etc/profile
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p  /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh \
         https://raw.githubusercontent.com/DennyZhang/devops_public/master/common_library/refresh_common_library.sh
fi
# export AVOID_REFRESH_LIBRARY=true
bash /var/lib/devops/refresh_common_library.sh "2549425636"
. /var/lib/devops/devops_common_library.sh
################################################################################################
## env variables:
##      branch_name: master
##      git_repo_url: git@github.com:DennyZhang/chef_community_cookbooks.git
##      chef_json:
################################################################################################
function basic_setup() {
    if ! which curl 1>/dev/null 2>&1; then
        echo "Install curl package"
        apt-get install -y curl
    fi

    if [ ! -f /root/git_update.sh ]; then
        echo "Basic setup and installation for chef deployment"
        curl -o /tmp/enable_chef_deployment.sh https://raw.githubusercontent.com/DennyZhang/devops_public/master/chef/enable_chef_depoyment.sh
        bash -e /tmp/enable_chef_deployment.sh
    fi
}

function chef_configuration() {
    local branch_name=${1?}
    local working_dir=${2?}
    local git_repo_url=${3?}
    local chef_json=${4?}

    local git_repo
    git_repo=$(echo "${git_repo_url%.git}" | awk -F '/' '{print $2}')

    chef_client_rb="$working_dir/client.rb"
    chef_json_file="$working_dir/client.json"

    echo "Generate chef configuration files: $chef_client_rb, $chef_json_file"
    cat > "$chef_client_rb" <<EOF
file_cache_path "/var/chef/cache"
cookbook_path ["$working_dir/$branch_name/$git_repo/cookbooks","$working_dir/$branch_name/$git_repo/community_cookbooks"]
EOF

    echo "$chef_json" > "$chef_json_file"
}

################################################################################################
# TODO: check OS
# TODO: check parameters
# Sample:
#       docker run -t -d --privileged -h mytest --name my-test -p 5122:22 denny/sshd:v1 /usr/sbin/sshd -D
#       docker exec -it my-test bash
#       export branch_name="DOCS-227-general-security"
#       export git_repo_url="git@github.com:DennyZhang/chef_community_cookbooks.git"
#       export chef_json="{\"run_list\": [\"recipe[general_security]\"], \"general_security\": {\"ssh_disable_passwd_login\": \"true\", \"ssh_disable_root_login\": \"false\"}}"

[ -n "$working_dir" ] || working_dir="/root/devops"

# TODO: remove file dependency on enable_chef_deployment.sh
basic_setup
git_update_code "$branch_name" "$working_dir" "$git_repo_url"
chef_configuration "$branch_name" "$working_dir" "$git_repo_url" "$chef_json"

echo "Run Chef update: chef-client --config $working_dir/client.rb -j $working_dir/client.json --local-mode"
chef-client --config "$working_dir/client.rb" -j "$working_dir/client.json" --local-mode

echo "Action Done"
## File : linux_apply_cookbook.sh ends