# frozen_string_literal: true

class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  include Hydra::User
  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles
  validates :uid, :email, presence: true, uniqueness: true

  def self.from_omniauth(access_token)
    unique_uid = access_token.uid
    User.where(provider: access_token.provider, uid: unique_uid).first_or_create do |user|
      user.uid = unique_uid
      user.provider = access_token.provider
      uid = access_token.uid.to_s
      user.email = uid.include?("@") ? uid : "#{uid}@princeton.edu"
    end
  end
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, omniauth_providers: [:cas]

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    uid
  end

  def admin?
    groups.include?("admin")
  end

  def staff?
    groups.include?("staff")
  end

  def campus_patron?
    persisted? && provider == "cas"
  end

  def anonymous?
    !persisted?
  end
end
