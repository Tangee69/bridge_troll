# frozen_string_literal: true

require 'rails_helper'

describe UserSearcher do
  let!(:user1) { create(:user, first_name: 'Abrahat', last_name: 'Zachson') }

  before { create(:user, first_name: 'Rochalle', last_name: 'Gorfdoor') }

  it 'returns the users matching a search query' do
    searcher = described_class.new(User, 'hat')
    expect(searcher.as_json).to contain_exactly({ id: user1.id, text: user1.full_name })
  end
end
