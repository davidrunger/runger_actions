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

      def execute
        result.total_cost = number_of_widgets * COST_PER_WIDGET
        result.incremented_phone_number = (Integer(user.phone) + 1).to_s
        result.uppercased_email = user.email.upcase
      end
    end
  end

  let(:action_klass) { ProcessOrder }

  describe '::requires' do
    def initialize_action(params)
      action_klass.new(params)
    end

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

            it 'raises an ActiveModel::StrictValidationFailed error' do
              expect { initialize_action(params) }.to raise_error(
                ActiveModel::StrictValidationFailed,
                "Phone can't be blank",
              )
            end
          end

          context 'when the provided ActiveRecord instance does meet those validations' do
            before { user.phone = "1#{Array.new(10) { rand(10).to_s }.join('')}" }

            it 'does not raise an error' do
              expect { initialize_action(params) }.not_to raise_error
            end
          end
        end
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
end
