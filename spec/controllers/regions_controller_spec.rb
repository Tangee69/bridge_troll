# frozen_string_literal: true

require 'rails_helper'

describe RegionsController do
  let!(:region) { create(:region) }

  describe 'permissions' do
    context 'a user that is not logged in' do
      context 'when rendering views' do
        render_views
        it 'can see the index page' do
          get :index
          expect(response).to be_successful
        end

        it 'can see the show page' do
          get :show, params: { id: region.id }
          expect(response).to be_successful
        end
      end

      it 'is not able to create a new region' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'is not able to edit a region' do
        get :edit, params: { id: region.id }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'is not able to delete a region' do
        delete :destroy, params: { id: region.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'a user that is logged in' do
      let(:user) { create(:user) }

      before do
        sign_in user
        user.regions << region
      end

      it 'can retrieve a JSON representation of a region' do
        get :show, params: { id: region.id }, format: :json
        json = JSON.parse(response.body)
        expect(json['name']).to eq(region.name)
        expect(json['users_subscribed_to_email_count']).to eq(1)
      end

      context 'when rendering views' do
        render_views

        it 'can see all the regions' do
          create(:region, name: 'Ultimate Region')
          get :index

          expect(response).to be_successful
          expect(response.body).to include('Ultimate Region')
        end
      end

      it 'is able to create a new region' do
        get :new
        expect(response).to be_successful

        expect do
          post :create, params: { region: { name: 'Fabulous Region' } }
        end.to change(Region, :count).by(1)
        expect(Region.last).to be_leader(user)
      end

      describe 'who is a region leader' do
        before do
          region.leaders << user
          region.reload
        end

        it 'is able to edit an region' do
          get :edit, params: { id: region.id }
          expect(response).to be_successful

          expect do
            put :update, params: { id: region.id, region: { name: 'Sandwich Region' } }
          end.to(change { region.reload.name })
          expect(response).to redirect_to(region_path(region))
        end
      end

      describe 'who is not a region leader' do
        it 'is not able to edit an region' do
          get :edit, params: { id: region.id }
          expect(response).to be_redirect
          expect(flash[:error]).to be_present

          expect do
            put :update, params: { id: region.id, region: { name: 'Sandwich Region' } }
          end.not_to(change { region.reload.name })
          expect(response).to be_redirect
          expect(flash[:error]).to be_present
        end
      end

      describe '#destroy' do
        it 'can delete a region that belongs to no locations' do
          expect do
            delete :destroy, params: { id: region.id }
          end.to change(Region, :count).by(-1)
        end

        it 'cannot delete a region that belongs to a location' do
          create(:location, region: region)
          expect do
            delete :destroy, params: { id: region.id }
          end.not_to change(Region, :count)
        end
      end
    end

    context 'a region lead' do
      before do
        user = create(:user)
        region.leaders << user
        sign_in user
      end

      describe 'for a region with multiple events' do
        let(:org1) { create(:user) }
        let(:org2) { create(:user) }

        before do
          location = create(:location, region: region)

          event1 = create(:event, location: location)
          event1.organizers << org1
          event1.organizers << org2

          event2 = create(:event, location: location)
          event2.organizers << org1
        end

        it 'can see a list of unique organizers' do
          get :show, params: { id: region.id }
          organizer_rsvps = assigns(:organizer_rsvps)
          expect(organizer_rsvps.map do |rsvp|
            [rsvp.user.full_name, rsvp.events_count]
          end).to contain_exactly([org1.full_name, 2], [org2.full_name, 1])
        end
      end
    end
  end
end
