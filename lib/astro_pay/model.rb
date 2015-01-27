module AstroPay
  class Model
    attr_accessor :error, :message

    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    # Creates a new instance of [AstroPay::Model].
    #
    # @param  attributes [Hash] with the following fields: :error, :message.
    # @return [AstroPay::Model] object.
    def initialize(attributes = {})
      self.attributes = attributes
    end

    # Sets a given hash values as attribute values for the class. It will try
    # to match the keys of the hash to existent attributes that have accessors.
    #
    # @param  attributes [Hash]
    # @note   If raised, [NoMethodError] will be caught and a message will be
    #         printed to the standard output.
    def attributes=(attributes = {})
      attributes.each do |name, value|
        begin
          send("#{name.to_s.underscore}=", value)
        rescue NoMethodError => e
          puts "Unable to assign #{name.to_s.underscore} with value #{value}. No such method."
        end
      end
    end

    # Gets the instance attributes.
    #
    # @return [Hash] with the attribute name as key, and the attribute value as
    #         value.
    def attributes
      Hash[instance_variables.map { |name| [name, instance_variable_get(name)] }]
    end
  end
end
