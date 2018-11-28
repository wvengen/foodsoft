module Types
  class GroupOrderType < BaseObject
    description "A group order"

    field :id, ID, null: false
    field :order, OrderType, null: false
    field :ordergroup, OrdergroupType, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, method: :updated_on
    #field :updated_by, UserType, null: false, method: :updated_by_user_id # @todo hide user's private fields

    #field :order_articles, [OrderArticle], null: true
  end
end
