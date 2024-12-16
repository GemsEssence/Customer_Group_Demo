module CustomerGroups
  module Delete
    class << self
      def call(customer_group, error_tracker = ::ErrorTracker.new('customer_group'))
        ActiveRecord::Base.transaction do

          validate_default_customer_group!(customer_group, error_tracker)
          delete_customer_group(customer_group, error_tracker)
          raise Exceptions::InvalidRecordException if error_tracker.has_error?

          { success: true, errors: [], result: customer_group }
        end
      rescue Exceptions::InvalidRecordException
        { success: false, errors: error_tracker.error_list, result: [] }
      end

      private

      def validate_default_customer_group!(customer_group, error_tracker)
        if customer_group.is_default
          error_tracker.add_errors("You can't delete default customer group")
          raise Exceptions::InvalidRecordException
        end
      end

      def delete_customer_group(customer_group, error_tracker)
        assign_customers_to_default_group(customer_group, error_tracker)
        customer_group.destroy
        error_tracker.add_errors(customer_group.errors.full_messages) if customer_group.errors.any?
      end


      def assign_customers_to_default_group(customer_group, error_tracker)
        default_group_id = CustomerGroups.default.first.id
        update_customers(customer_group.customers, default_group_id, error_tracker)

        reset_customer_postions(default_group_id, error_tracker)
      end

      def update_customers(customers, customer_group_id, error_tracker)
        customers.discarded.update_all(customer_group_id: customer_group_id)

        customers.kept.each do |customer|
          customer.update(customer_group_id: customer_group_id)

          if customer.errors.any?
            error_tracker.add_errors(customer.errors.full_messages)
            raise Exceptions::InvalidRecordException
          end
        end
      end

      def reset_customer_postions(customer_group_id, error_tracker)
        CustomerGroups::ResetCustomerPosition.call([customer_group_id], error_tracker)
      end
    end
  end
end
