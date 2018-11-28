module Types
  class QueryType < BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :config, ConfigType, null: true,
      description: "Configuration variables"

    field :viewer, UserType, null: false,
      description: "The currently authenticated user"

    field :orders, [OrderType], null: true do
      description "List orders"
      argument :is_open, Boolean, required: false
      argument :is_closed, Boolean, required: false
    end

    field :order, OrderType, null: true do
      description "Find order by id"
      argument :id, ID, required: true
    end

    def config
      # @todo fix https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/schema/field.rb#L375 to check for [] presence, not Hash
      FoodsoftConfig.to_hash
    end

    def viewer
      context[:current_user]
    end

    def orders(is_open: nil, is_closed: nil)
      scope = Order.all
      scope = scope.merge(Order.open) if is_open == true
      scope = scope.merge(Order.not_open) if is_open == false
      scope = scope.merge(Order.closed) if is_closed == true
      scope = scope.merge(Order.not_closed) if is_closed == false
      scope
    end

    def order(id:)
      Order.find(id)
    end
  end
end
