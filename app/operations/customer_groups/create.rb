module CustomerGroups
  module Create
    class << self
      def call(customer_group, customer_ids, error_tracker = ::ErrorTracker.new)

        ActiveRecord::Base.transaction do
          customer_group = save_customer_group(customer_group, error_tracker)

          assign_group_to_customers(customer_ids, customer_group.id, error_tracker)
          # assign_group_to_owner(customer_group.id, error_tracker)

          raise Exceptions::InvalidRecordException if error_tracker.has_error?

          { success: true, errors: [], result: customer_group }
        end
      rescue Exceptions::InvalidRecordException
        { success: false, errors: error_tracker.error_list, result: nil }
      end

      private

      def save_customer_group(customer_group, error_tracker)
        return customer_group if customer_group.save

        error_tracker.add_errors(customer_group.errors.full_messages)
        raise Exceptions::InvalidRecordException
      end

      def assign_group_to_customers(customer_ids, customer_group_id, error_tracker)
        customers = Customer.where(id: customer_ids)
        customer_group_ids = Customer.pluck(:customer_group_id)

        update_customers(customers, customer_group_id, error_tracker)
        reset_customer_position(customer_group_ids, customer_group_id, error_tracker)
      end

      def update_customers(customers, customer_group_id, error_tracker)
        is_saved_all_customers = true
        customers.each do |customer|
          customer.update(customer_group_id: customer_group_id)
          if is_saved_all_customers && customer.errors.any?
            is_saved_all_customers = false
            break;
          end
        end

        return if is_saved_all_customers

        error_tracker.add_errors("Unable to assign customer to customer group.")
      end

      def reset_customer_position(customer_group_ids, customer_group_id, error_tracker)
        reset_customer_position_for_existing_groups(customer_group_ids, error_tracker)
        reset_customer_position_for_new_group(customer_group_id, error_tracker)
      end

      def reset_customer_position_for_existing_groups(customer_group_ids, error_tracker)
        CustomerGroups::ResetCustomerPosition.call(customer_group_ids, error_tracker)
      end

      def reset_customer_position_for_new_group(customer_group_id, error_tracker)
        CustomerGroups::ResetCustomerPosition.call([customer_group_id], error_tracker)
      end
    end
  end
end
