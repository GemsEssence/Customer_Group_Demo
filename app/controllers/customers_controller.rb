class CustomersController < ApplicationController
  before_action :set_customer, except: [:index, :new, :create]

  def index
    permitted_params = params.permit(filter_params_mapping.keys, sft: [], prf: [])
    customer_ids = CustomerSearch.new(current_filter_params(permitted_params, filter_params_mapping).to_h).ids
    @customers = Customer.where(id: customer_ids).includes(:customer_group).order("customer_groups.name, customers.position")
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)
    @response = Customers::Create.call(customer_params)
    if @response[:success]
      respond_to do |format|
        flash.now[:notice] = "Customer has been successfully created."
        format.html do
          redirect_to web_customers_path
        end
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    session[:request_action] = request[:action]
  end

  def update
    @response = Customers::Update.call(@customer, current_user, customer_params)
    if @response[:success]
      respond_to do |format|
        flash.now[:notice] = "Customer has been successfully updated."
        format.html do
          redirect_to web_customers_path
        end
        format.turbo_stream
      end
    else
      render session[:request_action], status: :unprocessable_entity
    end
  end

  def destroy
    response = Customers::Delete.call(@customer)

    if response[:success]
      respond_to do |format|
        flash.now[:alert] = "Customer has been successfully deleted."
        format.html do
          redirect_to web_customers_path
        end
        format.turbo_stream
      end
    else
      flash.now[:alert] = response[:errors].first
    end
  end

  private

  def customer_params
    permitted_customer_params = params.require(:customer)
                            .permit(:name, :mobile_no, :customer_group_id,
                            :address, :email,
                            :is_active, :position,
                            :due_amount)
  end

  def filter_params_mapping
    {
      nom: :by_name_or_mobile_no,
      bjge: :by_balance_jar_greater_than_or_equal_to,
      bjle: :by_balance_jar_less_than_or_equal_to,
      dage: :by_due_amount_greater_than_or_equal_to,
      dale: :by_due_amount_less_than_or_equal_to,
      cg_id: :by_customer_group_id,
      pnmf: :by_payment_not_made_from,
      pndf: :by_product_not_deliverd_from,
      sft: :by_shift,
      gst: :by_gst_enabled,
      prf: :by_product_delivery_preference
    }
  end

  def set_customer
    @customer = Customer.find(params[:id])
  end
end