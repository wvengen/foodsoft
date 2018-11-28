module Types
  class ConfigFoodsoftType < BaseObject
    description "Foodsoft version"

    field :version, String, null: false, description: "Version number"
    field :revision, String, null: true, description: "Revision identifier"
    field :url, String, null: false, description: "homepage"

    def version
      Foodsoft::VERSION
    end

    def revision
      Foodsoft::REVISION
    end

    def url
      FoodsoftConfig[:foodsoft_url]
    end
  end
end
