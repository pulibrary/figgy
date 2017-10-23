# frozen_string_literal: true
class PlumDerivativeMover
  def self.link_or_copy(old, new)
    if Rails.env.production?
      FileUtils.ln(old, new, force: true)
    else
      FileUtils.cp(old, new)
    end
  end
end
