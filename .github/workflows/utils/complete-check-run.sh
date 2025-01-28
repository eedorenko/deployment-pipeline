#!/bin/bash

PROJECT=$1
VERSION=$2
REPO=$3

PROJECT_REPO=$4

echo $PROJECT
echo $VERSION
echo $REPO
echo $PROJECT_REPO


git clone --depth 1 -b $VERSION "https://automated:$REMOTE_TOKEN@github.com/$PROJECT_REPO" project


if [ $? -ne 0 ]; then
    echo "Tag $VERSION not found in $PROJECT_REPO"
    exit
fi

rm -r project

set -eo pipefail  # fail on error

# get a list of active check runs and iterate over them
gh api -X GET -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    /repos/$REPO/commits/tags/$PROJECT/$VERSION/check-runs | jq -r ".check_runs[] | select(.output.summary == \"$PROJECT/$VERSION\") | .id" | while read -r check_run_id; do
    # update the check run with the new status
    gh api -X PATCH -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -f name='Ensure version for '$PROJECT \
        -f 'output[title]=Ensure Version '$VERSION' for '$PROJECT \
        -f 'output[summary]='$VERSION \
        -f conclusion='success' \
        /repos/$REPO/check-runs/$check_run_id
    echo $check_run_id
done

