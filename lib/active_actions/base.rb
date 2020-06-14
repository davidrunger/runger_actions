# frozen_string_literal: true

class ActiveActions::Base
  class << self
    extend Memoist

    private

    memoize \
    def required_params
      {}
    end
  end
end
