```ruby
RAILS_ENV=staging CSV=config/vocab/lae_subjects.csv NAME="LAE Subjects" CATEGORY=category LABEL=subject URI=uri bundle exec rake vocab:load
RAILS_ENV=staging CSV=config/vocab/iso639-1.csv NAME="LAE Languages" bundle exec rake vocab:load
RAILS_ENV=staging CSV=config/vocab/lae_areas.csv NAME="LAE Areas" bundle exec rake vocab:load
RAILS_ENV=staging CSV=config/vocab/lae_genres.csv NAME="LAE Genres" LABEL=pul_label bundle exec rake vocab:load
```