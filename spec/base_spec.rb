# frozen_string_literal: true

RSpec.describe ActiveActions::Base do
  before do
    stub_const('ApplicationAction', Class.new(ActiveActions::Base))
    stub_const('User', Class.new(ActiveRecord::Base))
    stub_const('ProcessOrder', Class.new(ApplicationAction))

    ProcessOrder.class_eval do
      COST_PER_WIDGET ||= 1.5

      requires :number_of_widgets, Integer # numericality: { greater_than: 0 }
      requires :user, User do
        validates :email, presence: true, format: { with: /[a-z]+@[a-z]+\.[a-z]+/ }
        validates :phone, presence: true, format: { with: /[[:digit:]]{11}/ }
      end

      returns :total_cost, Float # numericality: { greater_than: 0 }
      returns :incremented_phone_number, String # format: { with: /[[:digit]]{11}/ }
      returns :uppercased_email, String # format: { with: /[A-Z]+@[A-Z]+\.[A-Z]+/ }
      returns :is_real_phone, [true, false]

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
        OpenStruct.new(success?: true, data: { is_real: true })
      end
    end
  end

  let(:action_klass) { ProcessOrder }
  let(:action_instance) { ProcessOrder.new(params) }
  let(:params) { { user: user, number_of_widgets: 32 } }
  let(:user) { User.new(email: 'davidjrunger@gmail.com', phone: '15551239876') }

  describe '::requires' do
    def initialize_action(params)
      action_klass.new(params)
    end

    describe 'validating inputs' do
      context 'when a required param is not provided when initializing the action' do
        let(:params) { { this_key_is_not_user: true, number_of_widgets: 2 } }

        it 'raises an error' do
          expect { initialize_action(params) }.to raise_error(ActiveActions::MissingParam)
        end
      end

      context 'when a required param is provided when initializing the action' do
        context "when the param's class is something other than the required class" do
          let(:params) { { user: 'This is not a `User`', number_of_widgets: 20 } }

          it 'raises an error' do
            expect { initialize_action(params) }.to raise_error(ActiveActions::TypeMismatch)
          end
        end

        context "when the param's class is of the required class" do
          let(:params) { { user: user, number_of_widgets: 10 } }
          let(:user) { User.new(email: 'davidjrunger@gmail.com') }

          context 'when the param has a custom validation block' do
            context 'when the provided ActiveRecord instance does not meet those validations' do
              before { expect(user.phone).to be_blank }

              it 'causes action#valid? to return false' do
                action = initialize_action(params)
                expect(action.valid?).to eq(false)
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
      expect(ProcessOrder.promised_values).to include(total_cost: Float)
      expect(ProcessOrder.promised_values).to include(incremented_phone_number: String)
      expect(ProcessOrder.promised_values).to include(uppercased_email: String)
    end
  end

  describe '::fails_with' do
    context 'when something goes wrong while executing the action' do
      before do
        expect(action_instance).to receive(:make_external_api_call).and_return(
          OpenStruct.new(success?: false, data: { errors: ['Our servers are down right now'] }),
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
  end
end
