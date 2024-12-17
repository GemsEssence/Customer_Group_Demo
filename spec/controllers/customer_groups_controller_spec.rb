require 'rails_helper'

RSpec.describe CustomerGroupsController, type: :controller do
  let(:customer_group) { create(:customer_group) }
  let(:valid_attributes) { { name: 'Test Group', is_deafult: true } }
  let(:invalid_attributes) { { name: '', is_deafult: true } }
  let(:customer) { create(:customer) }

  before do
    allow(controller).to receive(:current_user).and_return(create(:admin_user))
  end

  describe 'GET #index' do
    it 'assigns @groups' do
      get :index
      expect(assigns(:groups)).to eq([customer_group])
    end
  end

  describe 'GET #new' do
    it 'assigns a new CustomerGroup to @customer_group' do
      get :new
      expect(assigns(:customer_group)).to be_a_new(CustomerGroup)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new CustomerGroup' do
        expect {
          post :create, params: { customer_group: valid_attributes }
        }.to change(CustomerGroup, :count).by(1)
      end

      it 'redirects to the groups index with a success message' do
        post :create, params: { customer_group: valid_attributes }
        expect(flash[:notice]).to eq('Group has been successfully created.')
        expect(response).to redirect_to(web_groups_path)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new CustomerGroup' do
        expect {
          post :create, params: { customer_group: invalid_attributes }
        }.to change(CustomerGroup, :count).by(0)
      end

      it 'renders the new template with an unprocessable entity status' do
        post :create, params: { customer_group: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response.status).to eq(422)
      end
    end
  end

  describe 'GET #show' do
    it 'assigns @group_customers and @remaining_customers' do
      get :show, params: { id: customer_group.id }
      expect(assigns(:group_customers)).to eq(customer_group.customers)
      expect(assigns(:remaining_customers)).to eq(Customer.where.not(id: customer_group.customer_ids))
    end
  end

  describe 'GET #edit' do
    it 'assigns @customer_group' do
      get :edit, params: { id: customer_group.id }
      expect(assigns(:customer_group)).to eq(customer_group)
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      it 'updates the CustomerGroup and redirects to the show page with a success message' do
        allow(CustomerGroups::Update).to receive(:call).and_return({ success: true })

        patch :update, params: { id: customer_group.id, customer_group: valid_attributes }

        expect(flash[:notice]).to eq('Group name has been successfully updated.')
        expect(response).to redirect_to(web_group_path(customer_group))
      end
    end

    context 'with invalid parameters' do
      it 'does not update the CustomerGroup and renders the show template with errors' do
        allow(CustomerGroups::Update).to receive(:call).and_return({ success: false, errors: ['Update failed'] })

        patch :update, params: { id: customer_group.id, customer_group: invalid_attributes }

        expect(response).to render_template(:show)
        expect(response.status).to eq(422)
      end
    end

    context 'with customer changes (add/remove customers)' do
      it 'redirects with a success message when customers are added' do
        allow(CustomerGroups::Update).to receive(:call).and_return({ success: true })

        patch :update, params: { id: customer_group.id, customer_group: { customer_ids: [create(:customer).id] } }

        expect(flash[:notice]).to eq('Customer has been successfully added.')
        expect(response).to redirect_to(web_group_path(customer_group))
      end

      it 'redirects with a success message when customers are removed' do
        allow(CustomerGroups::Update).to receive(:call).and_return({ success: true })

        patch :update, params: { id: customer_group.id, customer_group: { remove_customer_ids: [create(:customer).id] } }

        expect(flash[:alert]).to eq('Customer has been successfully removed from group.')
        expect(response).to redirect_to(web_group_path(customer_group))
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when the deletion is successful' do
      it 'deletes the CustomerGroup and redirects to the index with a success message' do
        customer_group
        expect {
          delete :destroy, params: { id: customer_group.id }
        }.to change(CustomerGroup, :count).by(-1)
        expect(flash[:alert]).to eq('Group has been successfully deleted.')
        expect(response).to redirect_to(web_groups_path)
      end
    end

    context 'when the deletion fails' do
      it 'does not delete the CustomerGroup and shows an error message' do
        allow(CustomerGroups::Delete).to receive(:call).and_return({ success: false, errors: ['Delete failed'] })
        delete :destroy, params: { id: customer_group.id }
        expect(flash[:alert]).to eq('Delete failed')
        expect(response).to redirect_to(web_groups_path)
      end
    end
  end

  describe 'GET #customers' do
    it 'assigns active customers to @customers' do
      get :customers, params: { id: customer_group.id }
      expect(assigns(:customers)).to eq(customer_group.customers.where(is_active: true).order('name'))
    end
  end
end
