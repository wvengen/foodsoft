# encoding: utf-8
class Article < ActiveRecord::Base

  # @!attribute name
  #   @return [String] Article name
  # @!attribute unit
  #   @return [String] Unit, e.g. +kg+, +2 L+ or +5 pieces+.
  # @!attribute note
  #   @return [String] Short line with optional extra article information.
  # @!attribute availability
  #   @return [Boolean] Whether this article is available within the Foodcoop.
  # @!attribute manufacturer
  #   @return [String] Original manufacturer.
  # @!attribute origin
  #   Where the article was produced.
  #   ISO 3166-1 2-letter country code, optionally prefixed with region.
  #   E.g. +NL+ or +Sicily, IT+ or +Berlin, DE+.
  #   @return [String] Production origin.
  #   @see http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements
  # @!attribute price
  #   @return [Number] Net price
  #   @see ArticlePrice#price
  # @!attribute tax
  #   @return [Number] VAT percentage (10 is 10%).
  #   @see ArticlePrice#tax
  # @!attribute deposit
  #   @return [Number] Deposit
  #   @see ArticlePrice#deposit
  # @!attribute unit_quantity
  #   @return [Number] Number of units in wholesale package (box).
  #   @see ArticlePrice#unit_quantity
  # @!attribute order_number
  # Order number, this can be used by the supplier to identify articles.
  # This is required when using the shared database functionality.
  #   @return [String] Order number.
  # @!attribute article_category
  #   @return [ArticleCategory] Category this article is in.
  belongs_to :article_category
  # @!attribute supplier
  #   @return [Supplier] Supplier this article belongs to.
  belongs_to :supplier
  # @!attribute article_prices
  #   @return [Array<ArticlePrice>] Price history (current price first).
  has_many :article_prices, -> { order("created_at DESC") }

  # Replace numeric seperator with database format
  localize_input_of :price, :tax, :deposit
  # Get rid of unwanted whitespace. {Unit#new} may even bork on whitespace.
  normalize_attributes :name, :unit, :note, :manufacturer, :origin, :order_number

  scope :undeleted, -> { where(deleted_at: nil) }
  scope :available, -> { undeleted.where(availability: true) }
  scope :not_in_stock, -> { where(type: nil) }

  # Validations
  validates_presence_of :name, :unit, :price, :tax, :deposit, :unit_quantity, :supplier_id, :article_category
  validates_length_of :name, :in => 4..60
  validates_length_of :unit, :in => 2..15
  validates_numericality_of :price, :greater_than_or_equal_to => 0
  validates_numericality_of :unit_quantity, :greater_than => 0
  validates_numericality_of :deposit, :tax
  validates_uniqueness_of :name, :scope => [:supplier_id, :deleted_at, :type]
  
  # Callbacks
  before_save :update_price_history
  before_destroy :check_article_in_use
  
  # The financial gross, net plus tax and deposti
  def gross_price
    ((price + deposit) * (tax / 100 + 1)).round(2)
  end

  # The price for the foodcoop-member.
  def fc_price
    (gross_price  * (FoodsoftConfig[:price_markup] / 100 + 1)).round(2)
  end
  
  # Returns true if article has been updated at least 2 days ago
  def recently_updated
    updated_at > 2.days.ago
  end
  
  # If the article is used in an open Order, the Order will be returned.
  def in_open_order
    @in_open_order ||= begin
      order_articles = OrderArticle.where(order_id: Order.open.collect(&:id))
      order_article = order_articles.detect {|oa| oa.article_id == id }
      order_article ? order_article.order : nil
    end
  end
  
  # Returns true if the article has been ordered in the given order at least once
  def ordered_in_order?(order)
    order.order_articles.where(article_id: id).where('quantity > 0').one?
  end
  
  # this method checks, if the shared_article has been changed
  # unequal attributes will returned in array
  # if only the timestamps differ and the attributes are equal, 
  # false will returned and self.shared_updated_on will be updated
  def shared_article_changed?
    # skip early if the timestamp hasn't changed
    unless self.shared_article.nil? or self.shared_updated_on == self.shared_article.updated_on
      
      # try to convert units
      # convert supplier's price and unit_quantity into fc-size
      new_price, new_unit_quantity = self.convert_units
      new_unit = self.unit
      unless new_price and new_unit_quantity
        # if convertion isn't possible, take shared_article-price/unit_quantity
        new_price, new_unit_quantity, new_unit = self.shared_article.price, self.shared_article.unit_quantity, self.shared_article.unit
      end
      
      # check if all attributes differ
      unequal_attributes = Article.compare_attributes(
        {
          :name => [self.name, self.shared_article.name],
          :manufacturer => [self.manufacturer, self.shared_article.manufacturer.to_s],
          :origin => [self.origin, self.shared_article.origin],
          :unit => [self.unit, new_unit],
          :price => [self.price, new_price],
          :tax => [self.tax, self.shared_article.tax],
          :deposit => [self.deposit, self.shared_article.deposit],
          # take care of different num-objects.
          :unit_quantity => [self.unit_quantity.to_s.to_f, new_unit_quantity.to_s.to_f],
          :note => [self.note.to_s, self.shared_article.note.to_s]
        }
      )
      if unequal_attributes.empty?            
        # when attributes not changed, update timestamp of article
        self.update_attribute(:shared_updated_on, self.shared_article.updated_on)
        false
      else
        unequal_attributes
      end
    end
  end
  
  # compare attributes from different articles. used for auto-synchronization
  # returns array of symbolized unequal attributes
  def self.compare_attributes(attributes)
    unequal_attributes = attributes.select { |name, values| values[0] != values[1] and not (values[0].blank? and values[1].blank?) }
    unequal_attributes.collect { |pair| pair[0] }
  end
  
  # to get the correspondent shared article
  def shared_article
    self.order_number.blank? and return nil
    @shared_article ||= self.supplier.shared_supplier.shared_articles.find_by_number(self.order_number) rescue nil
  end
  
  # convert units in foodcoop-size
  # uses unit factors in app_config.yml to calc the price/unit_quantity
  # returns new price and unit_quantity in array, when calc is possible => [price, unit_quanity]
  # returns false if units aren't foodsoft-compatible
  # returns nil if units are eqal
  def convert_units
    if unit != shared_article.unit
      # legacy, used by foodcoops in Germany
      if shared_article.unit == "KI" and unit == "ST" # 'KI' means a box, with a different amount of items in it
        # try to match the size out of its name, e.g. "banana 10-12 St" => 10
        new_unit_quantity = /[0-9\-\s]+(St)/.match(shared_article.name).to_s.to_i
        if new_unit_quantity and new_unit_quantity > 0
          new_price = (shared_article.price/new_unit_quantity.to_f).round(2)
          [new_price, new_unit_quantity]
        else
          false
        end
      else # use ruby-units to convert
        fc_unit = (::Unit.new(unit) rescue nil)
        supplier_unit = (::Unit.new(shared_article.unit) rescue nil)
        if fc_unit and supplier_unit and fc_unit =~ supplier_unit
          conversion_factor = (fc_unit.convert_to(supplier_unit.units) / supplier_unit).scalar
          new_price = shared_article.price * conversion_factor
          new_unit_quantity = shared_article.unit_quantity / conversion_factor
          [new_price, new_unit_quantity]
        else
          false
        end
      end
    else
      nil
    end
  end

  def deleted?
    deleted_at.present?
  end

  def mark_as_deleted
    check_article_in_use
    update_column :deleted_at, Time.now
  end

  protected
  
  # Checks if the article is in use before it will deleted
  def check_article_in_use
    raise I18n.t('articles.model.error_in_use', :article => self.name.to_s) if self.in_open_order
  end

  # Create an ArticlePrice, when the price-attr are changed.
  def update_price_history
    if price_changed?
      article_prices.build(
        :price => price,
        :tax => tax,
        :deposit => deposit,
        :unit_quantity => unit_quantity
      )
    end
  end

  def price_changed?
    changed.detect { |attr| attr == 'price' || 'tax' || 'deposit' || 'unit_quantity' } ? true : false
  end
end
