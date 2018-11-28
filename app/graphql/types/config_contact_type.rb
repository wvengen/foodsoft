module Types
  class ConfigContactType < BaseObject
    description "Foodcoop contact details"

    field :street, String, null: true
    field :zipcode, String, null: true
    field :city, String, null: true
    field :country, String, null: true
    field :email, String, null: true
    field :phone, String, null: true
  end
end
