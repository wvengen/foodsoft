module Types
  class OrdergroupType < BaseObject
    description "An ordergroup"

    field :id, ID, null: false
    field :name, String, null: true
    field :description, String, null: true

    field :group_orders, [GroupOrderType], null: false do
      argument :is_open, Boolean, required: false
      argument :is_closed, Boolean, required: false
    end

    def group_orders(is_open: nil, is_closed: nil)
      scope = object.group_orders
      scope = scope.joins(:order).merge(Order.open) if is_open == true
      scope = scope.joins(:order).merge(Order.not_open) if is_open == false
      scope = scope.joins(:order).merge(Order.closed) if is_closed == true
      scope = scope.joins(:order).merge(Order.not_closed) if is_closed == false
      scope
    end
  end
end
