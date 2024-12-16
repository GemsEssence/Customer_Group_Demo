class CustomerSearch < Searchlight::Search
  def initialize(raw_options = {})
    super(raw_options)
  end

  def ids
    if options.present?
      sql = Customer.sanitize_sql([customer_search_base_query])
      options_with_search_methods.each do |_options, method_name|
        sql += public_send(method_name)
      end
      Customer.connection.exec_query(sql).cast_values
    else
      Customer.pluck(:id)
    end
  end

  def search_by_name_or_mobile_no
    Customer.sanitize_sql([' and (mobile_no ilike :search_text or customers.name ilike :search_text)', {
                            search_text: "%#{options[:by_name_or_mobile_no].strip}%"
                          }])
  end

  def search_by_customer_group_is_null
    ' and customers.customer_group_id is null'
  end

  def search_by_customer_group_id
    Customer.sanitize_sql([' and customers.customer_group_id in (:customer_group_id)', {
                            customer_group_id: options[:by_customer_group_id]
                          }])
  end

  def search_by_due_amount_greater_than_or_equal_to
    Customer.sanitize_sql([
                            ' and Coalesce((Coalesce(customer_due_amounts_table.due_amount, 0) - Coalesce(customer_advance_amounts_table.advance_amount, 0)),0) >= :amount_to_pay', { amount_to_pay: options[:by_due_amount_greater_than_or_equal_to] }
                          ])
  end

  def search_by_due_amount_less_than_or_equal_to
    Customer.sanitize_sql([
                            ' and Coalesce((Coalesce(customer_due_amounts_table.due_amount, 0) - Coalesce(customer_advance_amounts_table.advance_amount, 0)),0) <= :amount_to_pay', { amount_to_pay: options[:by_due_amount_less_than_or_equal_to] }
                          ])
  end

  private

  def customer_search_base_query
    Customer.all
  end
end
