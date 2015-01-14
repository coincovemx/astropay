module AstroPay
  class Model
    attr_accessor :error, :message

    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    def initialize(attributes = {})
      self.attributes = attributes
    end

    def attributes=(attributes = {})
      attributes.each do |name, value|
        begin
          send("#{name.to_s.underscore}=", value)
        rescue NoMethodError => e
          puts "Unable to assign #{name.to_s.underscore} with value #{value}. No such method."
        end
      end
    end

    def attributes
      Hash[instance_variables.map { |name| [name, instance_variable_get(name)] }]
    end
  end
end
