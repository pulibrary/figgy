# frozen_string_literal: true

require "sequel/database/logging"
require "active_support/notifications"

module Sequel
  # Patches Sequel to fire ActiveSupport::Notification events so we can tie that
  # into Lograge for JSON logs.
  #
  # This is pulled nearly verbatim from Sequel::Rails here:
  # https://github.com/TalentBox/sequel-rails/blob/aa4df50448650724361746c650d1c326b25bd1fe/lib/sequel_rails/sequel/database/active_support_notification.rb
  class Database
    def log_connection_yield(sql, conn, args = nil)
      sql_for_log = "#{connection_info(conn) if conn && log_connection_info}#{sql}#{"; #{args.inspect}" if args}"
      start = Time.now.to_f
      begin
        if Lograge::Sql.formatter
          ::ActiveSupport::Notifications.instrument(
            "sql.sequel",
            sql: sql,
            name: self.class,
            binds: args
          ) do
            yield
          end
        else
          yield
        end
      rescue => e
        log_exception(e, sql_for_log) unless @loggers.empty?
        raise
      ensure
        log_duration(Time.now.to_f - start, sql_for_log) unless e || @loggers.empty?
      end
    end

    def log_yield(sql, args = nil, &block)
      log_connection_yield(sql, nil, args, &block)
    end
  end
end
