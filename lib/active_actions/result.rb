# frozen_string_literal: true

class ActiveActions::Result
  def initialize
    @failure = nil
  end

  def success?
    @failure.nil?
  end
end
