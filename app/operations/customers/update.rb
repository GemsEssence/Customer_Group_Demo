module Customers
  module Update
    class << self
      def call(customer, customer_attributes, error_tracker = ::ErrorTracker.new)
        customer_group_id = customer.customer_group_id

        customer_params = build_customer_params(customer, customer_attributes, error_tracker)

        customer.assign_attributes(customer_params)

        ActiveRecord::Base.transaction do
          if customer.save
            reset_customer_group_position(customer_group_id, customer, error_tracker)

            { customer:, errors: [], success: true }
          else
            raise_errors_if_record_not_valid(customer, error_tracker)
          end
        end
      rescue Exceptions::InvalidRecordException
        { errors: error_tracker.error_list, customer:, success: false }
      end

      private

      def reset_customer_group_position(customer_group_id, customer, error_tracker)
        return true if customer.customer_group_id == customer_group_id

        CustomerGroups::ResetCustomerPosition.call([customer_group_id], error_tracker)
      end

      def build_customer_params(customer, customer_params, error_tracker)
        customer_params = customer_params.reject { |_k, v| v.nil? }

        return customer_params if valid_customer_group?(customer_params[:customer_group_id])

        # when customer_params[:customer_group_id] is nil or invalid_customer_group_id
        if customer.customer_group.blank?
          return customer_params.merge(customer_group_id: CustomerGroups.default.first.id)
        end

        customer_params.except(:customer_group_id)
      end

      def valid_customer_group?(customer_group_id)
        CustomerGroups.where(id: customer_group_id).exists?
      end

      def raise_errors_if_record_not_valid(record, error_tracker)
        return unless record.errors.any?

        error_tracker.add_errors(record.errors.full_messages)
        raise Exceptions::InvalidRecordException
      end
    end
  end
end
