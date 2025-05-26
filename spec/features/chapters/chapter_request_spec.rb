# frozen_string_literal: true

require 'rails_helper'

describe 'chapter pages' do
  let(:admin) { create(:user, admin: true) }
  let!(:chapter) { create(:chapter) }

  describe 'the index page' do
    it 'shows a list of chapters' do
      visit chapters_path

      expect(page).to have_content(chapter.name)
    end
  end

  it 'allows authorized users to create chapter leaders', :js do
    potential_leader = create(:user)

    sign_in_as(admin)

    visit chapter_path(chapter)

    click_on 'Edit Chapter Leaders'

    fill_in_select2(potential_leader.full_name)

    click_on 'Assign'

    within 'table' do
      expect(page).to have_content(potential_leader.full_name)
    end
  end

  it 'allows authorized users to delete chapter leaders', :js do
    leader = create(:user)
    chapter.leaders << leader

    sign_in_as(admin)

    visit chapter_path(chapter)

    click_on 'Edit Chapter Leaders'

    click_on 'Remove'

    expect(page).to have_content("Removed #{leader.full_name} as chapter leader.")
  end

  context 'for a chapter with past events' do
    let!(:event) { create(:event, chapter: chapter) }
    let(:organizer) { create(:user) }

    before do
      event.organizers << organizer
    end

    it 'allows authorized users to see a list of chapter organizers' do
      sign_in_as(admin)

      visit chapter_path(chapter)

      expect(page).to have_content(organizer.full_name)
    end
  end

  describe 'creating a new chapter' do
    let!(:org1) { create(:organization, name: 'Org1') }
    let(:org1_leader) { create(:user) }

    before do
      create(:organization, name: 'Org2')
      org1_leader.organization_leaderships.create(organization: org1)
    end

    it 'allows organization leaders to create a chapter in their org' do
      sign_in_as(org1_leader)

      visit new_chapter_path
      expect(page.all('#chapter_organization_id option').map(&:value)).to contain_exactly('', org1.id.to_s)

      select 'Org1', from: 'Organization'
      fill_in 'Name', with: 'Cantaloupe Chapter'

      expect do
        click_on 'Create Chapter'
      end.to change(Chapter, :count).by(1)

      expect(Chapter.last.name).to eq('Cantaloupe Chapter')
    end
  end

  describe 'editing a chapter' do
    let!(:org) { create(:organization) }
    let!(:existing_chapter) { create(:chapter, organization: org) }

    let(:org_leader) { create(:user) }

    before do
      org_leader.organization_leaderships.create(organization: org)
    end

    it 'allows organization leaders to change chapter names' do
      sign_in_as(org_leader)

      visit chapters_path
      click_on 'Edit'
      fill_in 'Name', with: 'Edited Name'

      click_on 'Update Chapter'

      expect(existing_chapter.reload.name).to eq('Edited Name')
    end
  end
end
