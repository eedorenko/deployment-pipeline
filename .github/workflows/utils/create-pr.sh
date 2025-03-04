#!/bin/bash

# Usage:
# create-pr.sh -s SOURCE_FOLDER -d DEST_FOLDER -r DEST_REPO -b DEST_BRANCH  -t TOKEN -r ENV_NAME -m AUTO_MERGE -l LABEL

# Example:
# create-pr.sh -s "/manifests" -d "/functional-testing" -r "https://github.com/microsoft/kalypso" -b "dev" -t "token" -r "dev" -m "N" -l "promoted"


# Creates a PR from the SOURCE_FOLDER to the DEST_FOLDER in the DEST_REPO in the DEST_BRANCH. It also creates a label on the PR, if specified.
# The script saves tracking information, such as PROMOTED_COMMIT_ID, VERSION and INAGE_NAME in the .github/tracking folder in the DEST_REPO. 


while getopts "s:d:r:b:i:t:e:m:l:" option;
    do
    case "$option" in
        s ) SOURCE_FOLDER=${OPTARG};;
        d ) DEST_FOLDER=${OPTARG};;
        r ) DEST_REPO=${OPTARG};;
        b ) DEST_BRANCH=${OPTARG};;
        t ) TOKEN=${OPTARG};;
        e ) ENV_NAME=${OPTARG};;
        m ) AUTO_MERGE=${OPTARG};;        
        l ) LABEL=${OPTARG};;
    esac
done
echo "List input params"
echo $SOURCE_FOLDER
echo $DEST_FOLDER
echo $DEST_REPO
echo $DEST_BRANCH
echo $IMAGE_NAME
echo $ENV_NAME
echo $LABEL
echo "end of list"

set -eo pipefail  # fail on error

SCRIPT_FOLDER=$(dirname $(realpath $0))

pr_user_name="Git Ops"
pr_user_email="agent@gitops.com"

git config --global user.email $pr_user_email
git config --global user.name $pr_user_name


# Clone manifests repo
echo "Clone manifests repo"
repo_url="${DEST_REPO#http://}"
repo_url="${DEST_REPO#https://}"
repo_url="https://automated:$TOKEN@$repo_url"

owner_repo="${DEST_REPO#https://github.com/}"
owner_repo="${owner_repo%.*}"

export GITHUB_TOKEN=
echo $TOKEN | gh auth login --with-token



echo "git clone $repo_url -b $DEST_BRANCH --depth 1 --single-branch"
git clone $repo_url -b $DEST_BRANCH --depth 1 --single-branch
repo=${DEST_REPO##*/}
repo_name=${repo%.*}
cd "$repo_name"
echo "git status"
git status

# Create a new branch 
deploy_branch_name=deploy/$PROMOTED_COMMIT_ID/$ENV_NAME

echo "Create a new branch $deploy_branch_name"
git checkout -b $deploy_branch_name

# Add generated manifests to the new deploy branch
mkdir -p $DEST_FOLDER
cp -r $SOURCE_FOLDER/* $DEST_FOLDER/

# Add tracking information
mkdir -p .github/tracking
echo "$PROMOTED_COMMIT_ID" > .github/tracking/Promoted_Commit_Id
echo "$VERSION" > .github/tracking/Version

git add -A
git status
# If there are changes, commit them
if [[ `git status --porcelain | head -1` ]]; then
    git commit --cleanup=verbatim -m "deployment $VERSION"
    


    #get last commit id
    commit_id=$(git rev-parse HEAD)

    # In case the deploy branch already exists, merge it with the current changes
    echo "Pull the deploy branch $deploy_branch_name"
    echo "git pull $repo_url $deploy_branch_name -s ours"
    git config pull.rebase false
    git pull $repo_url $deploy_branch_name -s ours || true

    # Push to the deploy branch 
    echo "Push to the deploy branch $deploy_branch_name"
    echo "git push --set-upstream $repo_url $deploy_branch_name"
    git push --set-upstream $repo_url $deploy_branch_name


    # Create a PR 
    echo "Create a PR to $DEST_BRANCH"
    

    if gh pr view $deploy_branch_name -R $owner_repo --json state | grep OPEN; then
        echo "PR already exists"
    else
        pr_response=$(gh pr create --base $DEST_BRANCH --head $deploy_branch_name --title "Deploy to '$ENV_NAME' '$VERSION'" --body "Deploy to '$ENV_NAME'")
        echo $pr_response
        pr_num="${pr_response##*pull/}"
        echo $pr_num
        # Add a label to the PR
        if [[ ! -z "$LABEL" ]]; then
            gh issue edit $pr_num --add-label $LABEL
        fi 
        # If auto merge is specified, merge the PR
        if [[ "$AUTO_MERGE" == "Y" ]]; then                
            gh pr merge $pr_num -m -d --repo $repo_url
        fi 

    fi
    $SCRIPT_FOLDER/start-check-run.sh $commit_id $owner_repo
fi 
