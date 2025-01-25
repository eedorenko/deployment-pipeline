    #!/bin/bash
    
    COMMIT_ID=$1
    REPO=$2

gh api -X POST -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -f name='Super Check' \
      -f head_sha=$COMMIT_ID \
      -f status='in_progress' \
      -f 'output[title]=My Check Run Title' \
      -f 'output[summary]=A *fancy* summary' \
      -f 'output[text]=More detailed Markdown **text**' \
      /repos/$REPO/check-runs
