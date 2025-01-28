#!/bin/bash

COMMIT_ID=$1
REPO=$2    


# Iterate over projects in snapshot.yaml e.g.
# snapshot:
#   plant-chat-api: 0.0.1-70
#   plant-chat-ui: 0.0.1-36


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


# -f 'output[summary]=A *fancy* summary' \
# -f 'output[text]=More detailed Markdown **text**' \


    # gh api -X PATCH -H "Accept: application/vnd.github+json" \
    #     -H "X-GitHub-Api-Version: 2022-11-28" \
    #     -f name='Ensure version for plant-chat-api' \
    #     -f 'output[title]=Ensure Version 0.0.1-70 for plant-chat-api' \
    #     -f 'output[summary]=0.0.1-70' \
    #     -f head_sha=fe3b3b9c51ef0da7a9a185ba25a57492db3c4efe \
    #     -f conclusion='success' \
    #     /repos/eedorenko/deployment-pipeline/check-runs/36249093684

    # gh api -X PATCH -H "Accept: application/vnd.github+json" \
    #     -H "X-GitHub-Api-Version: 2022-11-28" \
    #     -f name='Ensure version for plant-chat-api' \
    #     -f 'output[title]=Ensure Version 0.0.1-70 for plant-chat-api' \
    #     -f 'output[summary]=0.0.1-70' \
    #     -f head_sha=fe3b3b9c51ef0da7a9a185ba25a57492db3c4efe \
    #     -f conclusion='success' \
    #     /repos/eedorenko/deployment-pipeline/check-runs/36249093684

    # gh api -X PATCH -H "Accept: application/vnd.github+json" \
    #     -H "X-GitHub-Api-Version: 2022-11-28" \
    #     -f name='Ensure version for plant-chat-ui' \
    #     -f 'output[title]=Ensure Version 0.0.1-36 for plant-chat-ui' \
    #     -f 'output[summary]=0.0.1-36' \
    #     -f head_sha=fe3b3b9c51ef0da7a9a185ba25a57492db3c4efe \
    #     -f conclusion='success' \
    #     /repos/eedorenko/deployment-pipeline/check-runs/36249094032
