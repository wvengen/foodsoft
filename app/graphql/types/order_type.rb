module Types
  class OrderType < BaseObject
    description "An order"

    field :id, ID, null: false
    field :name, String, null: false
    field :starts, GraphQL::Types::ISO8601DateTime, null: false
    field :ends, GraphQL::Types::ISO8601DateTime, null: true
    field :boxfill, GraphQL::Types::ISO8601DateTime, null: true
    field :pickup, GraphQL::Types::ISO8601DateTime, null: true

    field :is_open, Boolean, null: false, method: :open?
    field :is_boxfill, Boolean, null: true, method: :boxfill?
    field :is_closed, Boolean, null: false, method: :closed?

    #field :order_articles, [OrderArticle], null: true
  end
end
