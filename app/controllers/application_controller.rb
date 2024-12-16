class ApplicationController < ActionController::Base
  # skip_before_action :verify_authenticity_token, only: [:your_action]

  def current_filter_params(permitted_params, filter_params_mapping)
    filter_params_mapping.each_with_object({}) do |(param_key, attribute), result|
      result[attribute] = permitted_params[param_key]
    end
  end
end
