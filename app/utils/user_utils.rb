# frozen_string_literal: true

# these methods created for use in rake tasks and db/seeds.rb
class UserUtils
  def self.promote_user_to_admin(user:, logger: Logger.new($stdout))
    logger.info "Ensuring #{user} is an admin user"
    user.roles << Role.first_or_create(name: "admin") unless user.admin?
    user
  end
end
