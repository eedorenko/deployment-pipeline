#!/bin/bash

COMMIT_ID=$1
REPO=$2    


# Iterate over projects in snapshot.yaml e.g.
# snapshot:
#   plant-chat-api: 0.0.1-70
#   plant-chat-ui: 0.0.1-36

SCRIPT_FOLDER=$(dirname $(realpath $0))

for project in $(yq eval '.snapshot | keys | .[]' $SNAPSHOT_FILE); do
    version=$(yq eval ".snapshot.$project" $SNAPSHOT_FILE)

    echo $project
    echo $version

    gh api -X POST -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -f name='Ensure version for '$project \
        -f 'output[title]=Ensure Version '$version' for '$project \
        -f 'output[summary]='$project/$version \
        -f head_sha=$COMMIT_ID \
        -f status='in_progress' \
        /repos/$REPO/check-runs

    tag="$project/$version"
    git tag $tag $COMMIT_ID
    git push -f origin $tag

    # take gitops repo from the projects.yaml file
    gitops_repo=$(yq eval ".projects.$project.gitops" $PROJECTS_FILE)

    $SCRIPT_FOLDER/complete-check-run.sh $project $version $REPO $gitops_repo

done
