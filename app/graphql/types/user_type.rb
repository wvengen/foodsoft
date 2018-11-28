module Types
  class UserType < BaseObject
    description "A user"

    field :id, ID, null: false
    field :name, String, null: true
    field :email, String, null: false
    field :locale, String, null: false

    field :ordergroup, OrdergroupType, null: true
  end
end
