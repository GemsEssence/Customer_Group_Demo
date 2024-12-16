class CustomerGroupSearch < Searchlight::Search
  def initialize(raw_options = {})
    @base_customer_group_relation = raw_options[:base_customer_group_relation]
    super(raw_options.except(:base_customer_group_relation))
  end

  def base_query
    @base_customer_group_relation
  end

  def search_by_name
    query.where('customer_groups.name ilike ?', "%#{options[:by_name].strip}%")
  end

  def search_by_customer_count_less_than_or_equal_to
    query
      .joins('left join customers on customer_groups.id = customers.customer_group_id')
      .group('customers.customer_group_id, customer_groups.id')
      .having('count(customers.customer_group_id) <= ?', options[:by_customer_count_less_than_or_equal_to])
  end

  def search_by_customer_count_greater_than_or_equal_to
    query
      .joins('left join customers on customer_groups.id = customers.customer_group_id')
      .group('customers.customer_group_id, customer_groups.id')
      .having('count(customers.customer_group_id) >= ?', options[:by_customer_count_greater_than_or_equal_to])
  end
end
