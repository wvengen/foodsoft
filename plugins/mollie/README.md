FoodsoftMollie
==============

This project adds support for online payments using [Mollie](https://www.mollie.com/) to Foodsoft.

* Make sure the gem is uncommented in foodsoft's `Gemfile`
* Enter your Mollie account details in `config/app_config.yml`

```yaml
  # Mollie payment settings
  use_mollie: true
  mollie_api_key: test_1234567890abcdef # Get this API-Key from the Mollie dashboard (required)
  mollie_currency: EUR                  # Currency for Mollie amount (optional; EUR by default)
```

When this plugin is enabled, a button is shown on the ordergroup's account
statement to credit the account.

To initiate a payment, redirect to `new_payments_mollie_path` at `/:foodcoop/payments/mollie/new`.
The following url parameters are recognised:
* ''amount'' - default amount to charge (optional)
* ''fixed'' - when "true", the amount cannot be changed (optional)
* ''title'' - page title (optional)
* ''label'' - label for amount (optional)
* ''min'' - minimum amount accepted (optional)

This plugin also introduces the foodcoop config option `use_mollie`, which can
be set to `false` to disable this plugin's functionality. May be useful in
multicoop deployments.
