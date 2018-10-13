module FoodsoftShop
  class Engine < ::Rails::Engine
    initializer "foodsoft_shop.assets.precompile" do |app|
      app.config.assets.precompile += %w(
        foodsoft_shop/bundle.js
        foodsoft_shop/bootstrap.css
        foodsoft_shop/famfamfam-flags.css
        foodsoft_shop/famfamfam-flags.png
        foodsoft_shop/glyphicons-halflings-regular.eot
        foodsoft_shop/glyphicons-halflings-regular.svg
        foodsoft_shop/glyphicons-halflings-regular.ttf
        foodsoft_shop/glyphicons-halflings-regular.woff
        foodsoft_shop/glyphicons-halflings-regular.woff2
      )
    end
  end
end
