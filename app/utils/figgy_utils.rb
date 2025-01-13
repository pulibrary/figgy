# frozen_string_literal: true

class FiggyUtils
  def self.with_rescue(exceptions, retries: 5)
    try = 0
    begin
      yield try
    rescue *exceptions => exc
      try += 1
      try <= retries ? retry : raise(exc)
    end
  end
end
