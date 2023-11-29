#!/bin/bash


upload_repo_url="https://uploads.github.com/repos/jokasimr/fluffy-octo-memory"
api_repo_url="https://api.github.com/repos/jokasimr/fluffy-octo-memory"

repo_url="https://github.com/scipp/scipp"
docs_url="https://github.com/scipp/scipp.github.io"

workdir=`mktemp -d`
pushd $workdir

git clone $repo_url repo
git clone $docs_url docs

cd repo
pwd

# The releases included here are the ones that show up in the dropdown menu on the scipp docs page
for release in 23.11 23.08 23.07 23.05 23.03 23.01 22.11 0.17 0.16 0.15 0.14 0.13 0.12 0.11 0.10 0.9 0.8
do 
    # Find all release tags (including minor releases)
    for tag in `git tag --list`
    do
        if [[ "$tag" =~ "$release"\.\d* ]]
        then
            echo $tag

            if [ -d "../docs/release/$release" ];
            then
                # Use already existing docs in scipp.github.io
                cp -r ../docs/release/$release documentation-$tag
            else
                continue
            fi

            zip -r documentation-$tag.zip documentation-$tag

            #curl -L \
            #  -X POST \
            #  -H "Accept: application/vnd.github+json" \
            #  -H "Authorization: Bearer $GITHUB_TOKEN" \
            #  -H "X-GitHub-Api-Version: 2022-11-28" \
            #  https://api.github.com/repos/jokasimr/fluffy-octo-memory/git/tags \
            #  -d '{"tag":"'$tag'","message":"initial version","object":"b108df12d94d7801d602448e4394e7aacda812e5","type":"commit","tagger":{"name":"Johannes Kasimir","email":"johannes.kasimir@ess.eu","date":"2023-11-29T09:00:00+01:00"}}'

            #echo sleep 10 after creating tag...
            #sleep 10

            curl -L \
              -X POST \
              -H "Accept: application/vnd.github+json" \
              -H "Authorization: Bearer $GITHUB_TOKEN" \
              -H "X-GitHub-Api-Version: 2022-11-28" \
              https://api.github.com/repos/jokasimr/fluffy-octo-memory/releases \
              -d '{"tag_name":"'"$tag"'","target_commitish":"main","name":"'"$tag"'","body":"Description of the release","draft":false,"prerelease":false,"generate_release_notes":false}'

            echo sleep 5 after creating release...
            sleep 5

            release_id=`curl -L \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                "$api_repo_url/releases/tags/$tag" \
                | jq '.id' \
                | tr -d '\n'`

            echo found release id $release_id

            echo sleep 10 after getting the release ID...
            sleep 10

            curl -L \
                -X POST \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                -H "Content-Type: application/octet-stream" \
                "$upload_repo_url/releases/$release_id/assets?name=documentation-$tag.zip" \
                --data-binary "@documentation-$tag.zip"

            echo
            echo sleep 10 after uploading assets...
            sleep 10


        fi
    done
done

popd
rm -rf $workdir
