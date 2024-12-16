module Titleize
  extend ActiveSupport::Concern

  included do
    before_validation :titleize_text_fields_value

    def titleize_text_fields_value
      self.class.titleize_fields.each do |titleize_field|
        titleize_text = send(titleize_field)&.titleize&.strip
        send("#{titleize_field}=", titleize_text)
      end
    end
  end

  module ClassMethods
    attr_reader :titleize_fields

    private

    def titleizable(*fields) # Alternatively `options = {}`
      @titleize_fields = fields       # Alternatively `options[:except] || []`
    end
  end
end
