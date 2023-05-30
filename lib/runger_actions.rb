# frozen_string_literal: true

module RungerActions ; end

require 'active_model'
require 'active_record'
require 'active_support/all'
require 'memo_wise'
require 'shaped'
Dir["#{File.dirname(__FILE__)}/runger_actions/**/*.rb"].each { |file| require file }

class RungerActions::ExecuteNotImplemented < RungerActions::Error ; end
class RungerActions::InvalidParam < RungerActions::Error ; end
class RungerActions::MissingParam < RungerActions::Error ; end
class RungerActions::MissingResultValue < RungerActions::Error ; end
class RungerActions::MutatingLockedResult < RungerActions::Error ; end
class RungerActions::RuntimeFailure < RungerActions::Error ; end
class RungerActions::TypeMismatch < RungerActions::Error ; end
