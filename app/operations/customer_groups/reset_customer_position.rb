module CustomerGroups
  module ResetCustomerPosition
    class << self
      def call(customer_group_ids, error_tracker = ::ErrorTracker.new)
        reset_customer_positions(customer_group_ids, error_tracker)

        raise Exceptions::InvalidRecordException if error_tracker.has_error?

        { success: true, errors: error_tracker.error_list, result: nil }

      rescue Exceptions::InvalidRecordException
        { success: false, errors: error_tracker.error_list, result: [] }
      end

      private

      def reset_customer_positions(customer_group_ids, error_tracker)
        customer_groups = CustomerGroups.where(id: customer_group_ids)
        customer_groups.each do |customer_group|
          customer_group.customers.order(:position, :id).each.with_index(1) do |customer, index|
            error_tracker.add_errors('unable to update position for customers') unless customer.update_column(:position, index)
          end

          customer_group.customers.discarded.order(:position, :id).each.with_index(1) do |customer, index|
            error_tracker.add_errors('unable to update position for customers') unless customer.update_column(:position, index)
          end
        end
      end
    end
  end
end
