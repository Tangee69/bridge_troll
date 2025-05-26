# frozen_string_literal: true

require 'rails_helper'

describe ChaptersController do
  let(:organization) { create(:organization, name: 'SpaceBridge') }
  let(:user) { create(:user, admin: true) }

  before do
    sign_in user
  end

  describe '#index' do
    let!(:chapter) { create(:chapter) }

    it 'shows all the chapters' do
      get :index
      expect(assigns(:chapters)).to contain_exactly(chapter)
    end
  end

  describe '#show' do
    let!(:chapter) { create(:chapter) }
    let!(:draft_event) { create(:event, current_state: :draft, chapter: chapter) }
    let!(:pending_event) { create(:event, current_state: :pending_approval, chapter: chapter) }
    let!(:published_event) { create(:event, chapter: chapter) }

    describe 'as an admin' do
      it 'shows all events' do
        expect(chapter.events).to contain_exactly(draft_event, pending_event, published_event)
        get :show, params: { id: chapter.id }
        expect(assigns(:chapter_events)).to contain_exactly(draft_event, pending_event, published_event)
      end
    end

    describe 'as a regular user' do
      let(:user) { create(:user) }

      it 'shows a list of published events' do
        get :show, params: { id: chapter.id }
        expect(assigns(:chapter_events)).to contain_exactly(published_event)
      end
    end
  end

  describe '#new' do
    it 'shows an empty chapter' do
      get :new
      expect(response).to be_successful
    end
  end

  describe '#create' do
    it 'creates a new chapter' do
      expect do
        post :create, params: { chapter: { name: 'Fabulous Chapter', organization_id: organization.id } }
      end.to change(Chapter, :count).by(1)
    end
  end

  describe '#edit' do
    let!(:chapter) { create(:chapter) }

    it 'shows a chapter edit form' do
      get :edit, params: { id: chapter.id }
      expect(response).to be_successful
    end
  end

  describe '#update' do
    let!(:chapter) { create(:chapter) }

    it 'changes chapter details' do
      expect do
        put :update, params: { id: chapter.id, chapter: { name: 'Sandwich Chapter' } }
      end.to(change { chapter.reload.name })
      expect(response).to redirect_to(chapter_path(chapter))
    end
  end

  describe '#destroy' do
    let!(:chapter) { create(:chapter) }

    it 'can delete a chapter that belongs to no events' do
      expect do
        delete :destroy, params: { id: chapter.id }
      end.to change(Chapter, :count).by(-1)
    end

    it 'cannot delete a chapter that belongs to a event' do
      create(:event, chapter: chapter)
      expect do
        delete :destroy, params: { id: chapter.id }
      end.not_to change(Chapter, :count)
    end
  end
end
