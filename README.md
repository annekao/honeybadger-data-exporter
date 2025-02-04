# Honeybadger Data Exporter

## Installation

Clone the repo, then install package dependencies:

```` sh
bundle install
````

## Usage

Set an environment variable called `HONEYBADGER_PRODUCTION_AUTH_TOKEN`, then run the exporter process:

```` sh
ruby script/export_notices.rb PROJECT_ID ERROR_CLASS OCCURRED_AFTER OCCURRED_BEFORE

# example
ruby script/export_notices.rb 123 "StandardError::*" "20230101" "20231201"
````
