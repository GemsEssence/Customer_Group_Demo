# params args = {
#   customer_ids: customer_ids,
#   remove_customer_ids: remove_customer_ids,
#   name: name,
#   customer_positions: customer_positions
# }

module CustomerGroups
  module Update
    class << self
      def call(customer_group, args, error_tracker = ::ErrorTracker.new)

        ActiveRecord::Base.transaction do
          validate_customer_postions(customer_group, args[:customer_positions], error_tracker)
          update_customer_group_name(customer_group, args[:name], error_tracker)
          remove_customers_from_groups(customer_group, args[:remove_customer_ids], error_tracker)
          assign_customers_to_group(customer_group, args[:customer_ids], error_tracker)
          update_customer_positions(customer_group, args[:customer_positions], error_tracker)

          raise Exceptions::InvalidRecordException if error_tracker.has_error?

          { success: true, errors: error_tracker.error_list, result: customer_group }
        end
      rescue Exceptions::InvalidRecordException
        { success: false, errors: error_tracker.error_list, result: customer_group }
      end

      private

      def validate_customer_postions(customer_group, customer_positions, error_tracker)
        return true if customer_positions.blank?

        is_valid_positions = valid_positions?(customer_group, customer_positions.pluck(:position))
        is_valid_customers = valid_customers?(customer_positions.pluck(:customer_id))

        return unless !is_valid_positions || !is_valid_customers

        error_tracker.add_errors('Invalid position provided')
        raise Exceptions::InvalidRecordException
      end

      def valid_customers?(customer_ids)
        customer_ids.count == customer_ids.uniq.count
      end

      def valid_positions?(customer_group, positions)
        # allowing only update one user position at a time.
        positions.count == 1 && positions.min >= 1 && positions.max <= customer_group.customers.count
      end

      def all_customers_belong_to_agency?(customer_ids)
        Customer.where(id: customer_ids).count == customer_ids.count
      end

      def update_customer_group_name(customer_group, name, error_tracker)
        return true if name.blank?
        customer_group.update(name:)
        error_tracker.add_errors(customer_group.errors.full_messages) if customer_group.errors.any?
      end

      def remove_customers_from_groups(customer_group, remove_customer_ids, error_tracker)
        default_customer_group_id = CustomerGroup.default.first.id
        customers = customer_group.customers.where(id: remove_customer_ids)
        customer_group_ids = customers.pluck(:customer_group_id)

        update_customers_group(customers, { customer_group_id: default_customer_group_id }, error_tracker)
        CustomerGroups::ResetCustomerPosition.call(customer_group_ids, error_tracker)
      end

      def assign_customers_to_group(customer_group, customer_ids, error_tracker)
        customers = Customer.where(id: customer_ids)
        customer_group_ids = customers.pluck(:customer_group_id)

        update_customers_group(customers, { customer_group_id: customer_group.id }, error_tracker)
        CustomerGroups::ResetCustomerPosition.call(customer_group_ids, error_tracker)
      end

      def update_customer_positions(customer_group, customer_positions, error_tracker)
        customer_positions.each do |customer_position|
          customers = customer_group.customers.where(id: customer_position[:customer_id])
          update_customers_group(customers, { position: customer_position[:position] }, error_tracker)
        end
      end

      def update_customers_group(customers, params, error_tracker)
        customers.find_each do |customer|
          customer.update(params)

          error_tracker.add_errors(customer.errors.full_messages) if customer.errors.any?
        end
      end
    end
  end
end
