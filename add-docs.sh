#!/bin/bash


upload_repo_url="https://uploads.github.com/repos/scipp/scipp"
api_repo_url="https://api.github.com/repos/scipp/scipp"

repo_url="https://github.com/scipp/scipp"
docs_url="https://github.com/scipp/scipp.github.io"

workdir=`mktemp -d`
pushd $workdir

git clone $repo_url repo
git clone $docs_url docs

cd repo
pwd

# The releases included here are the ones that show up in the dropdown menu on the scipp docs page
for release in do 23.11 23.08 23.07 23.05 23.03 23.01 22.11 0.17 0.16 0.15 0.14 0.13 0.12 0.11 0.10 0.9 0.8
do
    # Find all release tags (including minor releases)
    for tag in `git tag --list`
    do
        if [[ "$tag" =~ "$release"\.\d* ]]
        then
            docs_directory=../docs/release/`echo $release | sed 's/\(\d*\)\.0\(\d*\)/\1.\2/' | tr -d '\n'`
            echo Tag: $tag, Release directory: $docs_directory
            echo Sleep for 10s before zipping directory
            sleep 10

            if [ -d "$docs_directory" ];
            then
                # Use already existing docs in scipp.github.io
                cp -r $docs_directory documentation-$tag
            else
                echo "Did not find the docs - skipping"
                continue
            fi

            zip -r documentation-$tag.zip documentation-$tag

            release_id=`curl -L \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                "$api_repo_url/releases/tags/$tag" \
                | jq '.id' \
                | tr -d '\n'`

            echo "Found release id $release_id for tag $tag"
            echo Sleep 10 before uploading documentation asset... does the release id and the tag look right?
            sleep 10

            echo curl -L \
                -X POST \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                -H "Content-Type: application/octet-stream" \
                "$upload_repo_url/releases/$release_id/assets?name=documentation-$tag.zip" \
                --data-binary "@documentation-$tag.zip"

            echo
            echo Sleep 10 after uploading assets... does the response look good?
            sleep 10

        fi
    done
done

popd
rm -rf $workdir
