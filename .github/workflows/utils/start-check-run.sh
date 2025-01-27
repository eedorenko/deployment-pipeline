#!/bin/bash

COMMIT_ID=$1
REPO=$2    

# Iterate over projects in snapshot.yaml e.g.
# snapshot:
#   plant-chat-api: 0.0.1-70
#   plant-chat-ui: 0.0.1-36

cat $SNAPSHOT_FILE

for project in $(yq eval '.snapshot | keys | .[]' $SNAPSHOT_FILE); do
    version=$(yq eval ".snapshot.$project" $SNAPSHOT_FILE)

    echo $project
    echo $version

    gh api -X POST -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -f name='Ensure version for '$project \
        -f 'output[title]=Ensure Version '$version' for '$project \
        -f head_sha=$COMMIT_ID \
        -f status='in_progress' \
        /repos/$REPO/check-runs
done


# -f 'output[summary]=A *fancy* summary' \
# -f 'output[text]=More detailed Markdown **text**' \
