class ErrorTracker
  def initialize(name = "Error")
    @name = name
    @errors = []
  end

  def has_error?
    @errors.present?
  end

  def add_errors(errors)
    @errors.push(*([errors].flatten))
  end

  def error_list
    @errors.flatten.uniq
  end
end
