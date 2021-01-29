# frozen_string_literal: true

RSpec.describe ActiveActions::Base do
  before do
    stub_const('ApplicationAction', Class.new(ActiveActions::Base))
    stub_const('User', Class.new(ActiveRecord::Base))
    stub_const('COST_PER_WIDGET', 1.5)
    stub_const('DoubleNumber', Class.new(ApplicationAction))
    stub_const('ProcessOrder', Class.new(ApplicationAction))

    DoubleNumber.class_eval do
      requires :number, Numeric

      returns :number_doubled, Numeric

      def execute
        result.number_doubled = number * 2
      end
    end

    ProcessOrder.class_eval do
      requires :number_of_widgets, Integer, BigDecimal, numericality: { greater_than: 0 }
      requires :user, User do
        validates :email, presence: true, format: { with: /[a-z]+@[a-z]+\.[a-z]+/ }
        validates :phone, presence: true, format: { with: /[[:digit:]]{11}/ }
      end

      returns :total_cost, Float, numericality: { greater_than: 0 }
      returns :incremented_phone_number, String, format: { with: /[[:digit:]]{11}/ }
      returns :uppercased_email, String, format: { with: /[A-Z]+@[A-Z.]+/, allow_blank: true }
      returns :is_real_phone, true, false

      fails_with :bad_response_from_api

      def execute
        result.total_cost = number_of_widgets * COST_PER_WIDGET
        result.incremented_phone_number = (Integer(user.phone) + 1).to_s
        result.uppercased_email = user.email.upcase

        response_from_api = make_external_api_call
        if response_from_api.success?
          result.is_real_phone = response_from_api.data[:is_real]
        else
          result.bad_response_from_api!
        end
      end

      private

      def make_external_api_call
        # ... PhoneNumberVerificationService.post('/verify', data: { phone: user.phone }) ...
        # rubocop:disable Performance/OpenStruct
        OpenStruct.new(success?: true, data: { is_real: true })
        # rubocop:enable Performance/OpenStruct
      end
    end
  end

  let(:action_klass) { ProcessOrder }
  let(:action_instance) { ProcessOrder.new(params) }
  let(:params) { { user: user, number_of_widgets: 32 } }
  let(:user) { User.new(email: 'davidjrunger@gmail.com', phone: '15551239876') }

  describe '::run!' do
    subject(:run!) { DoubleNumber.run!(number: 8) }

    let(:double_number_action_double) { instance_double(DoubleNumber) }

    it 'calls the ::new! class method and the #run! instance method' do
      expect(DoubleNumber).to receive(:new!).and_return(double_number_action_double)
      expect(double_number_action_double).to receive(:run!)

      run!
    end
  end

  describe '::new!' do
    subject(:new!) { ProcessOrder.new!(number_of_widgets: 2, user: user) }

    it 'calls the ::new class method' do
      expect(ProcessOrder).to receive(:new).and_call_original
      new!
    end

    context 'when the provided params are valid' do
      it 'returns an action instance' do
        expect(new!).to be_a(ProcessOrder)
      end
    end

    context 'when the provided params are not valid' do
      before { user.email = 'not an email' }

      it 'raises an ActiveActions::InvalidParam error' do
        expect { new! }.to raise_error(ActiveActions::InvalidParam)
      end
    end
  end

  describe '::requires' do
    def initialize_action(params)
      action_klass.new(params)
    end

    describe 'validating inputs' do
      context 'when a required param is not provided when initializing the action' do
        let(:params) { { this_key_is_not_user: true, number_of_widgets: 2 } }

        it 'raises an error' do
          expect { initialize_action(params) }.to raise_error(
            ActiveActions::MissingParam,
            'Required param(s) `user` were not provided to the ProcessOrder action.',
          )
        end
      end

      context 'when a required param is provided when initializing the action' do
        context "when the param's class is something other than the required class" do
          let(:params) { { user: 'This is not a `User`', number_of_widgets: 20 } }

          it 'raises an error' do
            expect { initialize_action(params) }.to raise_error(
              ActiveActions::TypeMismatch,
              <<~ERROR.squish)
                One or more required params are of the wrong type: `user` is expected to be shaped
                like User, but was `"This is not a `User`"`.
              ERROR
          end
        end

        context "when the param's class is of the required class" do
          let(:params) { { user: user, number_of_widgets: 10 } }
          let(:user) { User.new(email: 'davidjrunger@gmail.com') }

          context 'when a required param fails to meet one or more specified validations' do
            let(:params) { { user: user, number_of_widgets: -20 } } # -20 violates `greater_than: 0`

            it 'raises an error' do
              expect { initialize_action(params) }.to raise_error(
                ActiveActions::TypeMismatch,
                <<~ERROR.squish)
                  One or more required params are of the wrong type: `number_of_widgets` is expected
                  to be shaped like Integer validating {:numericality=>{:greater_than=>0}} OR
                  BigDecimal validating {:numericality=>{:greater_than=>0}}, but was `-20`.
                ERROR
            end
          end

          context 'when the param has a custom validation block' do
            context 'when the provided ActiveRecord instance does not meet those validations' do
              before { expect(user.phone).to be_blank }

              it 'causes action#valid? to return false' do
                action = initialize_action(params)
                expect(action.valid?).to eq(false)
              end

              describe '#errors' do
                let(:action) { initialize_action(params) }

                it 'initially returns an empty ActiveModel::Errors instance' do
                  expect(action.errors).to be_a(ActiveModel::Errors)
                  expect(action.errors.any?).to eq(false)
                end

                context 'when #valid? has been called' do
                  before { action.valid? }

                  it 'populates #errors with details about the validation failures' do
                    expect(action.errors.to_hash).to eq({ phone: ["can't be blank", 'is invalid'] })
                  end
                end
              end
            end

            context 'when the provided ActiveRecord instance does meet those validations' do
              before { user.phone = "1#{Array.new(10) { rand(10).to_s }.join('')}" }

              it 'causes action#valid? to return true' do
                action = initialize_action(params)
                expect(action.valid?).to eq(true)
              end
            end
          end
        end

        context 'when a required param is a hash shape description' do
          before do
            stub_const('ActionWithShapedHashParam', Class.new(ApplicationAction))

            ActionWithShapedHashParam.class_eval do
              requires :message_params, 'store_id' => Integer
            end
          end

          def initialize_action(params)
            ActionWithShapedHashParam.new(params)
          end

          context 'when the action is initialized with a hash having the required shape' do
            let(:params) { { message_params: { 'store_id' => 20 } } }

            it 'does not raise an error' do
              expect { initialize_action(params) }.not_to raise_error
            end
          end

          context 'when the action is initialized with a hash not having the required shape' do
            # store_id is supposed to be a String, not a Symbol, according to the shape definition
            let(:params) { { message_params: { store_id: 20 } } }

            it 'raises an error' do
              expect { initialize_action(params) }.to raise_error(
                ActiveActions::TypeMismatch,
                <<~ERROR.squish)
                  One or more required params are of the wrong type: `message_params` is expected to
                  be shaped like { "store_id" => Integer }, but was `{:store_id=>20}`.
                ERROR
            end
          end
        end

        context 'when a required param is an array shape description' do
          before do
            stub_const('ActionWithShapedArrayParam', Class.new(ApplicationAction))

            ActionWithShapedArrayParam.class_eval do
              requires :numbers, [Numeric]
            end
          end

          def initialize_action(params)
            ActionWithShapedArrayParam.new(params)
          end

          context 'when the action is initialized with an array having the required shape' do
            let(:params) { { numbers: [2, 4, 8] } }

            it 'does not raise an error' do
              expect { initialize_action(params) }.not_to raise_error
            end
          end

          context 'when the action is initialized with an array not having the required shape' do
            # numbers is supposed to be an array of `Numeric`s, not `String`s
            let(:params) { { numbers: %w[two four eight] } }

            it 'raises an error' do
              expect { initialize_action(params) }.to raise_error(
                ActiveActions::TypeMismatch,
                <<~ERROR.squish)
                  One or more required params are of the wrong type: `numbers` is expected to be
                  shaped like [Numeric], but was `["two", "four", "eight"]`.
                ERROR
            end
          end
        end

        context 'when a required param is a Proc' do
          before do
            stub_const('ActionWithProcParamDescription', Class.new(ApplicationAction))

            ActionWithProcParamDescription.class_eval do
              requires :even_number, ->(number) { number.is_a?(Integer) && number.even? }
            end
          end

          def initialize_action(params)
            ActionWithProcParamDescription.new(params)
          end

          context 'when the action is initialized with an object that meets the proc test' do
            let(:params) { { even_number: 808 } }

            it 'does not raise an error' do
              expect { initialize_action(params) }.not_to raise_error
            end
          end

          context "when the action is initialized with an object that doesn't meet the proc test" do
            let(:params) { { even_number: 809 } }

            it 'raises an error' do
              expect { initialize_action(params) }.to raise_error(
                ActiveActions::TypeMismatch,
                Regexp.new(<<~ERROR.squish))
                  One or more required params are of the wrong type: `even_number` is expected to be
                  shaped like Proc test defined at
                  .*/spec/active_actions/base_spec\\.rb:\\d+, but was `809`.
                ERROR
            end
          end
        end
      end
    end

    describe 'setting up reader methods' do
      let(:action_instance) { action_klass.new(params) }
      let(:params) do
        {
          number_of_widgets: 100,
          user: User.new(email: 'davidjrunger@gmail.com', phone: '15551239876'),
        }
      end

      it 'creates a reader method for each required param that returns the param value' do
        expect(action_instance.number_of_widgets).to eq(params[:number_of_widgets])
        expect(action_instance.user).to eq(params[:user])
      end
    end
  end

  describe '::returns' do
    it "registers the specified return property with the class's registry" do
      expect(ProcessOrder.promised_values.transform_values(&:to_s)).to eq(
        incremented_phone_number: 'String validating {:format=>{:with=>/[[:digit:]]{11}/}}',
        is_real_phone: 'true OR false',
        total_cost: 'Float validating {:numericality=>{:greater_than=>0}}',
        uppercased_email:
          'String validating {:format=>{:with=>/[A-Z]+@[A-Z.]+/, :allow_blank=>true}}',
      )
    end

    describe 'Result writer methods' do
      let(:result) { action_instance.result }
      let(:new_phone_number) { '15551239877' }

      it 'has writer methods to assign the `returns`ed values' do
        expect {
          result.incremented_phone_number = new_phone_number
        }.to change {
          result.return_values[:incremented_phone_number]
        }.from(nil).to(new_phone_number)
      end

      context 'when attempting to assign a return value of the wrong type' do
        it 'raises an error' do
          expect {
            # this should raise, because `incremented_phone_number` is supposed to be a String
            result.incremented_phone_number = Integer(new_phone_number)
          }.to raise_error(ActiveActions::TypeMismatch, <<~ERROR.squish)
            Attemted to assign an invalid value for `result.incremented_phone_number` ; expected an
            object shaped like String validating {:format=>{:with=>/[[:digit:]]{11}/}} but got
            15551239877
          ERROR
        end
      end

      context 'when attempting to assign a return value that is of the wrong shape' do
        it 'raises an error' do
          expect {
            # this should raise, because `uppercased_email` is validated to have uppercase letters
            result.uppercased_email = 'a@b.c'
          }.to raise_error(ActiveActions::TypeMismatch, <<~ERROR.squish)
            Attemted to assign an invalid value for `result.uppercased_email` ; expected an object
            shaped like String validating {:format=>{:with=>/[A-Z]+@[A-Z.]+/, :allow_blank=>true}}
            but got "a@b.c"
          ERROR
        end
      end
    end

    describe 'Result reader methods' do
      context 'when #execute completes successfully and assigns one or more values to the result' do
        let(:result) { action_instance.run }

        it 'has reader methods on the returned Result to access those values' do
          expect(result.total_cost).to eq(COST_PER_WIDGET * params[:number_of_widgets])
        end
      end
    end

    context 'when #execute fails to set all promised `returns` values' do
      before do
        stub_const('BrokenMultiplyNumber', Class.new(ApplicationAction))

        BrokenMultiplyNumber.class_eval do
          requires :number, Numeric

          returns :number_tripled, Numeric
          returns :number_quadrupled, Float, Integer
          returns :number_quintupled, Numeric

          def execute
            result.number_tripled = number * 3
            # [because the lines below are commented out, it fails to assign the promised `returns`]
            # result.number_quadrupled = number * 4
            # result.number_quintupled = number * 5
          end
        end
      end

      let(:action_instance) { BrokenMultiplyNumber.new(number: 101) }

      it 'raises an error' do
        expect { action_instance.run }.to raise_error(
          ActiveActions::MissingResultValue,
          <<~ERROR.squish)
            BrokenMultiplyNumber failed to set all promised return values on its `result`. The
            following were missing on the `result`: `number_quadrupled` (should be shaped like
            Float OR Integer), `number_quintupled` (should be shaped like Numeric).
          ERROR
      end
    end
  end

  describe '::fails_with' do
    context 'when something goes wrong while executing the action' do
      before do
        expect(action_instance).to receive(:make_external_api_call).and_return(
          # rubocop:disable Performance/OpenStruct
          OpenStruct.new(success?: false, data: { errors: ['Our servers are down right now'] }),
          # rubocop:enable Performance/OpenStruct
        )
      end

      it 'can invoke a failure-bang method on the result object' do
        expect(action_instance.result).to receive(:bad_response_from_api!).and_call_original
        action_instance.execute
      end

      context 'when a failure-bang method has been invoked' do
        def execute_with_failure
          expect(action_instance.result).to receive(:bad_response_from_api!).and_call_original
          action_instance.execute
        end

        it 'causes the failure predicate method to return true' do
          expect { execute_with_failure }.
            to change { action_instance.result.bad_response_from_api? }.
            from(false).to(true)
        end

        it 'causes the #success? method to return false' do
          expect { execute_with_failure }.
            to change { action_instance.result.success? }.
            from(true).to(false)
        end
      end
    end
  end

  describe '#run' do
    subject(:run) { action_instance.run }

    it 'invokes the #execute method' do
      expect(action_instance).to receive(:execute).and_call_original
      run
    end

    it 'returns an instance of ProcessOrder::Result' do
      expect(run).to be_a(ProcessOrder::Result)
    end

    context 'when a param that is an ActiveRecord instance does not meet the validation rules' do
      before do
        user.update!(email: '')
        expect(action_instance).not_to be_valid
      end

      it 'does not raise an error' do
        expect { run }.not_to raise_error
      end
    end

    context 'when called with `raise_on_failure: true`' do
      subject(:run) { action_instance.run(raise_on_failure: true) }

      context 'when a `fails_with` condition is set during execution' do
        before do
          expect(action_instance).to receive(:make_external_api_call).and_return(
            # rubocop:disable Performance/OpenStruct
            OpenStruct.new(success?: false, data: { errors: ['Our servers are down right now'] }),
            # rubocop:enable Performance/OpenStruct
          )
        end

        it 'raises an ActiveActions::RuntimeFailure error' do
          expect { run }.to raise_error(ActiveActions::RuntimeFailure)
        end
      end
    end
  end

  describe '#run!' do
    subject(:run!) { action_instance.run! }

    context 'when the provided ActiveRecord params are all valid' do
      before { expect(action_instance).to be_valid }

      it 'invokes the #run method' do
        # don't `and_call_original` here because that prints a warning about "Using the last
        # argument as keyword parameters is deprecate"
        expect(action_instance).to receive(:run)
        run!
      end

      it 'returns an instance of ProcessOrder::Result' do
        expect(run!).to be_a(ProcessOrder::Result)
      end
    end

    context 'when a param that is an ActiveRecord instance does not meet the validation rules' do
      before do
        user.update!(email: '')
        user.update!(phone: '')
        expect(action_instance).not_to be_valid
      end

      it 'raises an error' do
        expect { run! }.to raise_error(
          ActiveActions::InvalidParam,
          <<~ERROR.squish)
            Email can't be blank, Email is invalid, Phone can't be blank, Phone is invalid
          ERROR
      end

      it "does not execute #run or the action's #execute method" do
        expect(action_instance).not_to receive(:execute)
        expect(action_instance).not_to receive(:run)

        expect { run! }.to raise_error(ActiveActions::InvalidParam)
      end
    end
  end

  context 'when an action class declares no `returns` or `fails_with`' do
    before do
      stub_const('PrintUserEmail', Class.new(ApplicationAction))

      PrintUserEmail.class_eval do
        requires :user, User do
          validates :email, presence: true
        end

        def execute
          puts("The user's email is #{user.email}.")
        end
      end
    end

    let(:action_instance) { PrintUserEmail.new(user: user) }

    it 'does not error when running the action' do
      expect(action_instance).to receive(:puts).with("The user's email is davidjrunger@gmail.com.")
      expect { action_instance.run }.not_to raise_error
    end
  end

  context 'when an action fails to implement #execute' do
    before do
      stub_const('AccidentallyDoNothing', Class.new(ApplicationAction))

      AccidentallyDoNothing.class_eval do
        requires :count, Integer

        # [this class fails to implement an #execute instance method]
      end
    end

    context 'when #run is called on an instance of the action' do
      def run_action
        AccidentallyDoNothing.new(count: 2).run
      end

      it 'raises an error about the failure to implement #execute' do
        expect { run_action }.to raise_error(
          ActiveActions::ExecuteNotImplemented,
          <<~ERROR.squish)
            All ActiveActions classes must implement an #execute instance method, but
            AccidentallyDoNothing fails to do so.
          ERROR
      end
    end
  end

  context 'when an action does not require any input params' do
    before do
      stub_const('PrintCurrentTime', Class.new(ApplicationAction))

      PrintCurrentTime.class_eval do
        # [note that this action class has no `requires`]

        def execute
          puts(Time.now)
        end
      end
    end

    context 'when instantiating the action without any params' do
      let(:action_instance) { PrintCurrentTime.new }

      it 'does not raise an error' do
        expect { action_instance }.not_to raise_error
      end

      context 'when running the action' do
        let(:run_action) { action_instance.run }

        before do
          expect(action_instance).to receive(:puts) # suppress `puts` from actually printing output
        end

        it 'does not raise an error' do
          expect { run_action }.not_to raise_error
        end
      end
    end
  end

  context 'when an attempt is made to mutate a `result` outside of #execute' do
    def run_action_and_attempt_to_mutate_result
      result = DoubleNumber.new(number: 4).run
      result.number_doubled = 10
    end

    it 'raises an error' do
      expect { run_action_and_attempt_to_mutate_result }.to raise_error(
        ActiveActions::MutatingLockedResult,
        <<~ERROR.squish)
          You are attempting to assign a value to an instance of DoubleNumber::Result outside of the
          DoubleNumber#execute method. This is not allowed; you may only assign values to the
          `result` within the #execute method.
        ERROR
    end
  end
end
