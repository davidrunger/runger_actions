# frozen_string_literal: true

RSpec.describe ActiveActions::Base do
  before do
    stub_const('ApplicationAction', Class.new(ActiveActions::Base))
    stub_const('User', Class.new(ActiveRecord::Base))
    stub_const('SomeAction', Class.new(ApplicationAction))

    SomeAction.class_eval do
      requires :user, User do
        validates :phone, presence: true
      end
    end
  end

  let(:action_klass) { SomeAction }

  describe '::requires' do
    def initialize_action(params)
      action_klass.new(params)
    end

    context 'when a required param is not provided when initializing the action' do
      let(:params) { { this_key_is_not_user: true } }

      it 'raises an error' do
        expect { initialize_action(params) }.to raise_error(ActiveActions::MissingParam)
      end
    end

    context 'when a required param is provided when initializing the action' do
      context "when the param's class is something other than the required class" do
        let(:params) { { user: 'This is not an instance of the `User` class' } }

        it 'raises an error' do
          expect { initialize_action(params) }.to raise_error(ActiveActions::TypeMismatch)
        end
      end

      context "when the param's class is of the required class" do
        let(:params) { { user: user } }
        let(:user) { User.new }

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

  describe '::required_parameters' do
    subject(:required_params) { action_klass.send(:required_params) }

    it 'returns a hash' do
      expect(required_params).to be_a(Hash)
    end
  end
end
