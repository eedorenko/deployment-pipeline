#!/bin/bash

# Usage:
# generate-manifests.sh PROJECTS_FILE SNAPSHOT_FILE ENVIRONMENT_BRANCH FOLDER_WITH_MANIFESTS GENERATED_MANIFESTS_FOLDER

# Example:
# generate-manifests.sh "projects.yaml" "snapshot.yaml" dev helm "generated-manifests"

# Projects file example:
# projects:
#   plant-chat-api:
#     source: plant-chat-api_CI-9232
#     config: plant-chat-api-config-ci-9232
#     gitops: plant-chat-api-gitops-ci-9232
#   plant-chat-ui:
#     source: plant-chat_CI-9232 
#     config: plant-chat-config-ci-9232
#     gitops: plant-chat-gitops-ci-9232

PROJECTS_FILE=$1
SNAPSHOT_FILE=$2
ENVIRONMENT_BRANCH=$3
FOLDER_WITH_MANIFESTS=$4
GENERATED_MANIFESTS_FOLDER=$5


echo $PROJECTS_FILE
echo $SNAPSHOT_FILE
echo $ENVIRONMENT_BRANCH
echo $FOLDER_WITH_MANIFESTS
echo $GENERATED_MANIFESTS_FOLDER

set -euo pipefail

github_prefix=https://github.com/
values_file_name='values.yaml'
gen_manifests_file_name='gen_manifests.yaml'

mkdir -p $GENERATED_MANIFESTS_FOLDER

# iterate over projects in projects.yaml
for project in $(yq eval '.projects | keys | .[]' $PROJECTS_FILE); do
    source_repo=$(yq eval ".projects.$project.source" $PROJECTS_FILE)
    config_repo=$(yq eval ".projects.$project.config" $PROJECTS_FILE)
    gitops_repo=$(yq eval ".projects.$project.gitops" $PROJECTS_FILE)

    echo "Cloning config repo $config_repo"
    git clone $github_prefix/$config_repo -b $ENVIRONMENT_BRANCH --depth 1 --single-branch $project-config
    pushd $project-config
        for dir in `find . -type d \( ! -name . \)`; do
            # Generate manifests for every leaf folder with values.yaml in config
            if [ -z "$(find $dir -mindepth 1 -type d \( ! -name . \))" ] && [ -f $dir/$values_file_name ]; then
                manifests_dir=$GENERATED_MANIFESTS_FOLDER/$project/$dir
                mkdir -p $manifests_dir   
                mkdir -p $manifests_dir/descriptor   
                deployment_target=$(basename $dir)
                helm template $FOLDER_WITH_MANIFESTS -f $PROJECTS_FILE -f $SNAPSHOT_FILE --set project=$project --set deploymentTarget=$deployment_target-snapshot --set path=$dir > $manifests_dir/$gen_manifests_file_name                
                cat $manifests_dir/$gen_manifests_file_name
                pushd $manifests_dir 
                
                # Generate kustomization.yaml
                kustomize create --autodetect
                popd

                helm template $FOLDER_WITH_MANIFESTS -f $PROJECTS_FILE -f $SNAPSHOT_FILE --set project=$project --set deploymentTarget=$deployment_target-descriptor --set path=$dir/descriptor > $manifests_dir/descriptor/$gen_manifests_file_name

                if [ $? -gt 0 ]
                then
                    echo "Could not render manifests"
                    exit 1
                fi
                
            fi
        done

    popd 

done







