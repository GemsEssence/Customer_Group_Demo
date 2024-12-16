module Customers
  module Create
    class << self
      def call(customer_params, error_tracker = ::ErrorTracker.new('create_customer'))

        customer = build_customer(customer_params, error_tracker)

        customer = save_customer(customer, error_tracker)

        { success: true, errors: [], result: customer}

      rescue Exceptions::InvalidRecordException
        { success: false, errors: error_tracker.error_list, result: nil }
      end

      private

      def save_customer(customer, error_tracker)
        return customer if customer.save

        error_tracker.add_errors(customer.errors.full_messages)
        raise Exceptions::InvalidRecordException
      end

      def build_customer(customer_params, error_tracker)
        params = build_customer_params(customer_params)
        Customers.new(params)
      end

      def build_customer_params(customer_params)
        return customer_params if valid_customer_group?(customer_params[:customer_group_id])

        customer_params.merge(customer_group_id: CustomerGroups.default.first.id)
      end

      def valid_customer_group?(customer_group_id)
        CustomerGroups.where(id: customer_group_id).exists?
      end
    end
  end
end
