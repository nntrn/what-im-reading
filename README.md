# what i'm reading

```sh
./scripts/build-data.sh --out _data
./scripts/build-data.sh --url https://url/to/annotations.json

# locally
./scripts/build-data.sh annotations.json
```

```sh
bundle install    # or bundle install --local
bundle exec jekyll build
bundle exec jekyll serve
```

## Building _data

```sh
# create _data/books.json
jq -L scripts 'include "annotations"; create_book_data' annotations.json

# create _data/activity.json
jq -L scripts 'include "annotations"; create_activity_data' annotations.json

# create _data/genres.json
jq -L scripts 'include "annotations"; create_genre_data' annotations.json

# create _data/words.json
jq -L scripts 'include "annotations"; create_word_data' annotations.json

# create _data/stats/bookmarks_per_month.json
jq -L scripts 'include "annotations"; stats_bookmarks_per_month' activity.json 

# create _data/stats/month.json
jq -L scripts 'include "annotations"; stats_month' activity.json

# create _data/history.json
jq -L scripts 'include "annotations"; stats_history' activity.json 
```

## Build activity

create _pages/activity.txt

```sh
jq -L scripts --slurpfile books _data/books.json \
  'include "annotations"; stats_history_text' _data/history.json
```

# trigger update

```sh
curl -H "Accept: application/vnd.github.everest-preview+json" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  --request POST \
  -d '{"event_type":"update_data","client_payload": {"data_url": "URL HERE", "ref": "stage" }}' \
  https://api.github.com/repos/nntrn/what-im-reading/dispatches
```

