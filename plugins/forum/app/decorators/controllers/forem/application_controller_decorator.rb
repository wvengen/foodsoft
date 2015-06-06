Forem::ApplicationController.class_eval do
  # Remove foodcoop in url. It appears to be present already for the
  # mounted engine, so including it here adds another "?foodcoop=f"
  # to the url.
  def default_url_options(options = {})
    {}
  end
end
