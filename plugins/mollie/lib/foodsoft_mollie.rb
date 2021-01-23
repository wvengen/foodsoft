require 'mollie-api-ruby'
require 'foodsoft_mollie/engine'

module FoodsoftMollie
  def self.enabled?
    !!FoodsoftConfig[:use_mollie] && api_key.present?
  end

  def self.api_key
    FoodsoftConfig[:mollie_api_key].presence
  end

  def self.currency
    FoodsoftConfig[:mollie_currency].presence || 'EUR'
  end
end
