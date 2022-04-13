## Sidekiq

Q: Sidekiq jobs fail with `ArgumentError: A copy of PlumCharacterizationService has been removed from the module tree but is still active!`.

A: This is a code reloading problem. Restart sidekiq to resolve it.

## Creating initial admin user locally

Q: How do I create an admin user on my local machine for development?

A: Login to Figgy with CAS, and then use the Rails console `bundle exec rails c`:
```
role = Role.create!(name: "admin")
user = User.last
user.roles << role
user.save!
```