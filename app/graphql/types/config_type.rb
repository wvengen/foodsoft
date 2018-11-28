module Types
  class ConfigType < BaseObject
    description "Configuration"

    # details
    field :name, String, null: true
    field :homepage, String, null: true
    field :contact, ConfigContactType, null: true, method: :object

    # settings
    field :currency_unit, String, null: false
    field :currency_space, Boolean, null: false
    field :default_locale, String, null: false
    field :price_markup, Float, null: true
    field :tolerance_is_costly, Boolean, null: false
    field :use_apple_points, Boolean, null: false
    field :use_tolerance, Boolean, null: false

    # layout
    field :page_footer_html, String, null: true
    field :webstats_tracking_code_html, String, null: true

    # help and version
    field :applepear_url, String, null: true
    field :help_url, String, null: true
    field :foodsoft, ConfigFoodsoftType, null: false, method: :object

    def page_footer_html
      # also see footer layout
      if object[:page_footer].present?
        object[:page_footer]
      elsif object[:homepage].present?
        ActionController::Base.helpers.link_to(object[:name], object[:homepage])
      else
        object[:name]
      end
    end

    def webstats_tracking_code_html
      object[:webstats_tracking_code].presence
    end
  end
end
