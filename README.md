# what i'm reading

```sh
./scripts/build-data.sh --out _data
./scripts/build-data.sh --remote
./scripts/group.sh > _pages/activity.md
```

```sh
bundle install
bundle exec jekyll build
bundle exec jekyll serve
```

# trigger update

```
curl -H "Accept: application/vnd.github.everest-preview+json" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    --request POST --data '{"event_type": "update_data"}' \
    https://api.github.com/repos/nntrn/what-im-reading/dispatches
```