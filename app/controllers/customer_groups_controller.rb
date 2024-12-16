class CustomerGroupsController < ApplicationController
  before_action :set_customer_group, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create]

  def index
    permitted_params = params.permit(filter_params_mapping.keys)
    groups = CustomerGroupSearch.new(current_filter_params(permitted_params, filter_params_mapping).to_h.merge(base_customer_group_relation: CustomerGroup.all)).results
    @groups = groups.order("name")
  end

  def new
    @customer_group = CustomerGroup.new
  end

  def create
    @customer_group = CustomerGroup.new(create_customer_group_params)
    @response = CustomerGroups::Create.call(@customer_group, [])
    if @response[:success]
      respond_to do |format|
        flash.now[:notice] = "Group has been successfully created."
        format.html do
          redirect_to web_groups_path
        end
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @group_customers = customer_group_customers
    @remaining_customers = remaining_customers
  end

  def edit
  end

  def update
    total_group_customers = customer_group_customers.count
    @response = CustomerGroups::Update.call(@customer_group, update_customer_group_params)
    @group_customers = customer_group_customers
    @remaining_customers = remaining_customers
    if @response[:success]
      respond_to do |format|
        flash_message_for_update(total_group_customers)
        format.html do
          redirect_to web_group_path(@customer_group)
        end
        format.turbo_stream
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    response = CustomerGroups::Delete.call(@customer_group)
    if response[:success]
      respond_to do |format|
        flash.now[:alert] = "Group has been successfully deleted."
        format.html do
          redirect_to web_groups_path
        end
        format.turbo_stream
      end
    else
      flash.now[:alert] = response[:errors].first
    end
  end

  def customers
    customer_group = CustomerGroup.find params[:id]
    @customers = customer_group.customers.where(is_active: true).order('name')
  end

  private

  def filter_params_mapping
    {
      n: :by_name,
      bjge: :by_balance_jar_greater_than_or_equal_to,
      bjle: :by_balance_jar_less_than_or_equal_to,
      ccge: :by_customer_count_greater_than_or_equal_to,
      ccle: :by_customer_count_less_than_or_equal_to,
      dage: :by_due_amount_greater_than_or_equal_to,
      dale: :by_due_amount_less_than_or_equal_to,
    }
  end

  def set_customer_group
    @customer_group = CustomerGroup.find(params[:id])
  end

  def create_customer_group_params
    params.permit(:name, :is_deafult)
  end

  def update_customer_group_params
    params
      .permit(:name, :customer_ids => [], :remove_customer_ids => [], :customer_positions => [:customer_id, :position])
      .with_defaults(customer_ids: [], remove_customer_ids: [], customer_positions: [])
  end

  def customer_group_customers
    @customer_group.customers
  end

  def remaining_customers
    Customer.where.not(id: @group_customers.ids)
  end

  def flash_message_for_update(total_group_customers)
    if total_group_customers < @group_customers.count
      flash[:notice] = "Customer has been successfully added."
    elsif total_group_customers > @group_customers.count
      flash[:alert] = "Customer has been successfully removed from group."
    elsif @customer_group.name_previously_changed?
      flash[:notice] = "Group name has been successfully updated."
    end
  end
end
