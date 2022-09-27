# frozen_string_literal: true

module ActiveActions ; end

require 'active_support/all'
require 'active_model'
require 'active_record'
require 'memoist'
require 'shaped'
Dir["#{File.dirname(__FILE__)}/active_actions/**/*.rb"].sort.each { |file| require file }

class ActiveActions::ExecuteNotImplemented < ActiveActions::Error ; end
class ActiveActions::InvalidParam < ActiveActions::Error ; end
class ActiveActions::MissingParam < ActiveActions::Error ; end
class ActiveActions::MissingResultValue < ActiveActions::Error ; end
class ActiveActions::MutatingLockedResult < ActiveActions::Error ; end
class ActiveActions::RuntimeFailure < ActiveActions::Error ; end
class ActiveActions::TypeMismatch < ActiveActions::Error ; end
