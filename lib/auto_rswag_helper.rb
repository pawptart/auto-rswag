# frozen_string_literal: true

# This class performs conversions of the response data
# based on test metadata.
class AutoRswagHelper
  class << self
    def convert_response(response)
      return response if [Array, Hash].include?(response.class)

      body = response.body
      body = body.respond_to?(:read) ? body.read : body

      JSON.parse(body)
    rescue StandardError
      body
    end

    def map_fields(object)
      if object.is_a? Array
        object = {
          type: :array,
          items: map_fields(object.first)
        }
      elsif object.is_a?(Hash)
        object = {
          type: :object,
          properties: map_object_keys(object)
        }
      end
      object
    end

    def map_object_keys(object)
      object.keys.each do |key|
        value = object.delete(key)
        converted_key = convert(key)
        if value.is_a? Hash
          object[converted_key] = {
            type: :object,
            properties: value
          }
          map_fields(value)
        elsif value.is_a? Array
          object[converted_key] = {
            type: :array,
            items: [value.first]
          }
          map_fields(value)
        else
          object[converted_key] = parse_field(value)
        end
      end
    end

    def convert(key)
      key.to_sym
    end

    def parse_field(value)
      type = value.nil? ? :string : value.class.to_s.downcase.to_sym
      {
        type: type,
        example: value,
        'x-nullable' => true
      }
    end
  end
end
