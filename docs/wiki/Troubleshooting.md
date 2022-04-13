# RSpec Test Suites
For some environments, it may be the case that RSpec test suites are abruptly no longer able to be run after tests using derivative generation were executed.

For these cases two possible steps were needed to be followed in order to restore a working environment:

## Restart PostgreSQL
macOS:
```bash
brew services restart postgresql
```

_if this proves to be ineffective, please try the following:_

## Reinitialize the PostgreSQL database cluster
macOS:
```bash
mv /usr/local/var/postgres /usr/local/var/postgres.broken
initdb /usr/local/var/postgres -E utf8
brew services start postgresql
```