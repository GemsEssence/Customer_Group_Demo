module Customers
  module Delete
    class << self
      def call(customer, error_tracker = ::ErrorTracker.new('customer_delete'))
        ActiveRecord::Base.transaction do
          customer.customer_group_id = CustomerGroup.default.first.id

          customer.destroy

          if customer.errors.any?
            error_tracker.add_errors(customer.errors.full_messages)
            raise Exceptions::InvalidRecordException
          else
            raise Exceptions::InvalidRecordException if error_tracker.has_error?
          end

          { success: true, errors: error_tracker.error_list, result: customer }
        end
      rescue Exceptions::InvalidRecordException
        { success: false, errors: error_tracker.error_list, result: nil }
      end
    end
  end
end
