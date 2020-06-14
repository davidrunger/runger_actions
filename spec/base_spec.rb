# frozen_string_literal: true

RSpec.describe ActiveActions::Base do
  class self::ApplicationAction < ActiveActions::Base
  end

  class self::SomeAction < ApplicationAction
  end

  describe '::required_params' do
    subject(:required_params) { SomeAction.send(:required_params) }

    it 'returns a hash' do
      expect(required_params).to be_a(Hash)
    end
  end
end
