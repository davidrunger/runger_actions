# frozen_string_literal: true

RSpec.describe ActiveActions::Base do
  class module_parent::ApplicationAction < ActiveActions::Base
  end

  class module_parent::SomeAction < module_parent::ApplicationAction
  end

  klass = module_parent::SomeAction
  let(:action_klass) { klass }

  describe '::required_parameters' do
    subject(:required_params) { action_klass.send(:required_params) }

    it 'returns a hash' do
      expect(required_params).to be_a(Hash)
    end
  end
end
