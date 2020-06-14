# frozen_string_literal: true

class ActiveActions::Base
  extend Memoist

  class << self
    extend Memoist

    def requires(param_name, param_klass, &blk)
      required_params[param_name] = param_klass

      if (param_klass < ActiveRecord::Base) && blk.present?
        register_validator_klass(param_name, param_klass, blk)
      end

      define_reader_method(param_name)
    end

    def define_reader_method(param_name)
      define_method(param_name) do
        @params[param_name]
      end
    end

    def register_validator_klass(param_name, param_klass, blk)
      validator_klass = const_set("#{param_name.to_s.camelize}Validator", Class.new)
      validator_klass.include(ActiveModel::Model)
      validator_klass.attr_accessor(*param_klass.column_names)
      validator_klass.class_eval(&blk)
      validators[param_name] = validator_klass
    end

    def returns(param_name, param_klass)
      promised_values[param_name] = param_klass
      result_klass.class_eval do
        attr_accessor param_name
      end
    end

    def fails_with(error_type)
      result_klass.class_eval do
        define_method("#{error_type}!") do
          @failure = error_type
        end

        define_method("#{error_type}?") do
          @failure == error_type
        end
      end
    end

    memoize \
    def result_klass
      const_set('Result', Class.new(ActiveActions::Result))
    end

    memoize \
    def required_params
      {}
    end

    memoize \
    def promised_values
      {}
    end

    memoize \
    def validators
      {}
    end
  end

  attr_reader :errors

  def initialize(params)
    @params = params
    @errors = ActiveModel::Errors.new(self)
    validate_required_params!
  end

  def run
    execute
    result
  end

  def valid?
    run_custom_validations
    @errors.blank?
  end

  memoize \
  def result
    self.class::Result.new
  end

  private

  def run_custom_validations
    self.class.required_params.each_key do |param_name|
      validator_klass = self.class.validators[param_name]
      next if validator_klass.nil?

      model_instance = @params[param_name]
      validator_instance = validator_klass.new(model_instance.attributes)
      if !validator_instance.valid?
        @errors = validator_instance.errors
      end
    end
  end

  def validate_required_params!
    self.class.required_params.each do |param_name, param_klass|
      raise(ActiveActions::MissingParam) unless @params.keys.include?(param_name)
      raise(ActiveActions::TypeMismatch) unless @params[param_name].is_a?(param_klass)
    end
  end
end
