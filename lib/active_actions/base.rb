# frozen_string_literal: true

class ActiveActions::Base
  extend Memoist

  class << self
    extend Memoist

    def requires(param_name, param_klasses, &blk)
      param_klasses = Array(param_klasses)
      required_params[param_name] = param_klasses

      if (param_klasses.size == 1) && (param_klasses.first < ActiveRecord::Base) && blk.present?
        register_validator_klass(param_name, param_klasses.first, blk)
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

    def returns(param_name, param_klasses)
      param_klasses = Array(param_klasses)
      promised_values[param_name] = param_klasses
      result_klass.class_eval do
        attr_reader param_name

        define_method("#{param_name}=") do |value|
          if locked?
            raise(ActiveActions::MutatingLockedResult, <<~ERROR.squish)
              You are attempting to assign a value to an instance of #{self.class} outside of the
              #{self.class.module_parent}#execute method. This is not allowed; you may only assign
              values to the `result` within the #execute method.
            ERROR
          end

          if param_klasses.none? { value.is_a?(_1) }
            raise(ActiveActions::TypeMismatch, <<~ERROR.squish)
              Attemted to assign `#{value.is_a?(String) ? value.inspect : value}` for
              `result.#{param_name}` ; expected an instance of
              #{param_klasses.map(&:name).join(' or ')} but got an instance of #{value.class}.
            ERROR
          end

          instance_variable_set(:"@#{param_name}", value)
        end
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

  # We can't specify keyword arguments for this method because we don't know which keywords/params
  # the method will need to accept; that's defined by the user.
  #
  # rubocop:disable Style/OptionHash
  def initialize(params = {})
    @params = params
    @errors = ActiveModel::Errors.new(self)
    validate_required_params!
  end
  # rubocop:enable Style/OptionHash

  def run
    if !respond_to?(:execute)
      raise(ActiveActions::ExecuteNotImplemented, <<~ERROR.squish)
        All ActiveActions classes must implement an #execute instance method, but #{self.class}
        fails to do so.
      ERROR
    end

    execute
    result.lock!
    result
  end

  def run!
    if valid?
      run
    else
      raise(ActiveActions::InvalidParam, @errors.full_messages.join(', '))
    end
  end

  def valid?
    run_custom_validations
    @errors.blank?
  end

  memoize \
  def result
    self.class.result_klass.new
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
    missing_params = self.class.required_params.keys - @params.keys
    if missing_params.any?
      raise(ActiveActions::MissingParam, <<~ERROR.squish)
        Required param(s) #{missing_params.map { "`#{_1}`" }.join(', ')} were not provided to
        the #{self.class} action.
      ERROR
    end

    type_mismatches = []
    self.class.required_params.each do |param_name, param_klasses|
      unless param_klasses.any? { @params[param_name].is_a?(_1) }
        type_mismatches << [param_name, param_klasses, @params[param_name]]
      end
    end

    if type_mismatches.any?
      messages =
        type_mismatches.map do |param_name, param_klasses, value|
          <<~MESSAGE.squish
            `#{param_name}` is expected to be a #{param_klasses.map(&:name).join(' or ')}, but was
            `#{value.is_a?(String) ? value.inspect : value}`,
            which is a #{value.class}
          MESSAGE
        end
      raise(ActiveActions::TypeMismatch, <<~ERROR.squish)
        One or more required params are of the wrong type: #{messages.join(' ; ')}.
      ERROR
    end
  end
end