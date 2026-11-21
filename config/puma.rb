# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

# The environment variable WEB_CONCURRENCY may be set to a default value based
# on dyno size. To manually configure this value use heroku config:set
# WEB_CONCURRENCY.
#
# Increasing the number of workers will increase the amount of resting memory
# your dynos use. Increasing the number of threads will increase the amount of
# potential bloat added to your dynos when they are responding to heavy
# requests.
#
# Starting with a low number of workers and threads provides adequate
# performance for most applications, even under load, while maintaining a low
# risk of overusing memory.
workers 3
threads_count = 1
threads(threads_count, threads_count)
worker_timeout 3600

preload_app!

# Puma rejects methods outside a short list with a 501. The read-only WebDAV
# mount at /dav (WebdavController) needs PROPFIND. Writes (MKCOL, LOCK, etc.)
# still get rejected here, which is fine for a read-only share.
supported_http_methods(Puma::Const::SUPPORTED_HTTP_METHODS + ["PROPFIND"])

environment ENV.fetch("RACK_ENV", "development")
