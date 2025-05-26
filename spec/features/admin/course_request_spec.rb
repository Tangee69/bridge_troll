# frozen_string_literal: true

require 'rails_helper'

describe 'courses', :js do
  let(:admin) { create(:user, admin: true) }

  before do
    sign_in_as(admin)
  end

  it 'allows an admin to create a course with levels' do
    visit '/courses/new'

    fill_in 'Name', with: 'Lisp'
    fill_in 'Title', with: 'Lisp for Llamas'
    fill_in 'Description', with: 'An introductory Lisp course for Llamas'

    click_on 'Add another level'
    within '.course-levels .fields', match: :first do
      select 'blue', from: 'Color'
      fill_in 'Title', with: 'Beginner'
      fill_in 'Level description', with: "* Desires adventure\n* Has hill climbing skills"
    end

    click_on 'Create Course'

    expect(page).to have_content('Listing courses')

    created_course = Course.last
    expect(created_course.title).to eq('Lisp for Llamas')

    created_level = Level.last
    expect(created_level.title).to eq('Beginner')
    expect(created_level.level_description).to eq(['Desires adventure', 'Has hill climbing skills'])
  end

  describe 'editing courses' do
    let!(:course) { create(:course, levels_count: 3) }

    it 'allows an admin to remove levels from a course' do
      visit "/courses/#{course.id}/edit"

      expect(page).to have_css('.course-levels .fields', count: 3)
      within '.course-levels .fields', match: :first do
        click_on 'Remove Level'
      end
      expect(page).to have_css('.course-levels .fields', count: 2)

      click_on 'Update Course'
      expect(page).to have_content('Listing courses')

      expect(course.reload.levels.length).to eq(2)
    end
  end

  describe 'reordering course levels' do
    let!(:course) { create(:course, levels_count: 2) }

    it 'reorders course levels if you assign the position to an existing level' do
      expect(course.levels.order(:num).to_a.map(&:color)).to eq(%w[blue green])

      visit "/courses/#{course.id}/edit"

      within '.course-levels .fields:nth-of-type(2)' do
        select '1', from: 'Position'
      end

      click_on 'Update Course'
      expect(page).to have_content('Listing courses')

      expect(course.levels.order(:num).to_a.map(&:color)).to eq(%w[green blue])
    end
  end
end
