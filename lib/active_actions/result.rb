# frozen_string_literal: true

class ActiveActions::Result
  attr_reader :error_message, :return_values

  def initialize(action:)
    @action = action
    @return_values = {}
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
