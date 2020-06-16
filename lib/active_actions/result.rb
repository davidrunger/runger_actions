# frozen_string_literal: true

class ActiveActions::Result
  def initialize
    @failure = nil
  end

  def lock!
    @locked = true
  end

  def locked?
    @locked == true
  end

  def success?
    @failure.nil?
  end
end
