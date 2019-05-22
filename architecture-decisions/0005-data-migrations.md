# 5. Data Migrations

Date: 2019-05-22

## Status

Accepted

## Context

There are several ways of migrating data, including:

* Using an ActiveRecord Migration
* Writing a Rake task and running it after deploying a code update

## Decisions

1. When migrations do not change the database structure or otherwise break the application, we should
   write a Rake task to migrate data.

## Consequences

1. Data migration code is typically only used once, and can then be removed from the application.  This is
   a good reason to avoid using ActiveRecord Migrations, which must remain in the application.
1. Deployment will require coordination, since the Rake task must be run after the code has been deployed.
   This is more work to deploy than an ActiveRecord Migration.
