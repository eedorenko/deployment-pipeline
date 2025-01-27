#!/bin/bash

PROJECT=$1
VERSION=$2
REPO=$3

set -eo pipefail  # fail on error

gh api -X GET -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    /repos/$REPO/check-runs | jq -r '.check_runs[] | select(.status == "in_progress")'

# get a list of active check runs and iterate over them
gh api -X GET -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    /repos/$REPO/commits/tags/$PROJECT/$VERSION/check-runs | jq -r '.check_runs[] | select(.status == "in_progress") | .id' | while read -r check_run_id; do
    # # update the check run with the new status
    # gh api -X PATCH -H "Accept: application/vnd.github+json" \
    #     -H "X-GitHub-Api-Version: 2022-11-28" \
    #     -f name='Ensure version for '$PROJECT \
    #     -f 'output[title]=Ensure Version '$VERSION' for '$PROJECT \
    #     -f 'output[summary]='$VERSION \
    #     -f conclusion='success' \
    #     /repos/$REPO/check-runs/$check_run_id
    echo $check_run_id
done

# gh api -X GET -H "Accept: application/vnd.github+json" \
#     -H "X-GitHub-Api-Version: 2022-11-28" \
#     /repos/eedorenko/deployment-pipeline/check-runs
    
    
#      | jq -r '.check_runs[] | select(.status == "in_progress")'

