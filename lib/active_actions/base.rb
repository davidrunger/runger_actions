# frozen_string_literal: true

class ActiveActions::Base
  class << self
    extend Memoist

    def requires(param_name, param_klass, &blk)
      required_params[param_name] = param_klass

      if (param_klass < ActiveRecord::Base) && blk.present?
        validator_klass = const_set("#{param_name.to_s.camelize}Validator", Class.new)
        validator_klass.include(ActiveModel::Model)
        validator_klass.attr_accessor(*param_klass.column_names)
        validator_klass.class_eval(&blk)
        validators[param_name] = validator_klass
      end
    end

    def returns(param_name, param_klass)
      promised_values[param_name] = param_klass
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

  def initialize(params)
    @params = params
    validate_params!
  end

  private

  def run_custom_validations!
    self.class.required_params.each_key do |param_name|
      validator_klass = self.class.validators[param_name]
      next if validator_klass.nil?

      instance = @params[param_name]
      validator_instance = validator_klass.new(instance.attributes)
      if !validator_instance.valid?
        attribute, messages = validator_instance.errors.to_hash.first
        validator_instance.errors.add(attribute, :invalid, strict: true, message: messages.first)
      end
    end
  end

  def validate_params!
    validate_required_params!
    run_custom_validations!
  end

  def validate_required_params!
    self.class.required_params.each do |param_name, param_klass|
      raise(ActiveActions::MissingParam) unless @params.keys.include?(param_name)
      raise(ActiveActions::TypeMismatch) unless @params[param_name].is_a?(param_klass)
    end
  end
end
