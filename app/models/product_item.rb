# -*- coding: utf-8 -*-
class ProductItem < ActiveRecord::Base
  class Type
  end

  class Proxy
    def initialize(items)
      @items = items
    end

    private
    def item_of(item_code)
      @items.detect{|i| i.item_code == item_code }
    end
  end # Type

  belongs_to :ruby_kaigi

  class << self
    def kaigi(year)
      ProductItem::Proxy.new(
        ProductItem.all(:include => 'ruby_kaigi').select{|p| p.ruby_kaigi.year == Integer(year)})
    end
  end

  def available?
    0 < stock
  end

  def sold_out?
    !available?
  end

  def label
    "product_item.#{item_code}"
  end

  def individual_sponsor?
    !!(item_code =~ /individual_sponsor/)
  end

  def now_on_sale?
    ready_for_sale? && open_sale_at.past? && available?
  end
end

%w[rk10 rk10_party rk10_individual_sponsor].each do |_type|
  (class << ProductItem::Type; self; end).class_eval do
    define_method(_type) { _type }
  end
  ProductItem::Proxy.class_eval do
    define_method(_type) do
      item_of(_type)
    end
  end
end
