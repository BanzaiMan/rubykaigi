module Paypal
  class EncryptedForm
    attr_accessor :cmd, :order, :return_url, :notify_url
    def initialize(order, return_url, notify_url)
      @cmd = "_s-xclick"
      @order = order
      @return_url = return_url
      @notify_url = notify_url
    end

    def encrypted
      values = {
        :business => business_email,
        :cmd => '_cart',
        :upload => 1,
        :return => return_url,
        :invoice => order.id,
        :notify_url => notify_url,
        :cert_id => cert_id,
        :currency_code => 'JPY'
      }
      order.line_items.each_with_index do |item, index|
        values.merge!({
            "amount_#{index + 1}" => item.subtotal_price,
            "item_name_#{index + 1}" => I18n.t(item.product_item.label),
            "item_number_#{index + 1}" => item.product_item.item_code,
            "quantity_#{index + 1}" => item.quantity
          })
      end
      encrypt_for_paypal(values)
    end

    private

    def business_email
      configatron.paypal.business_email
    end

    def cert_id
      configatron.paypal.cert_id
    end

    def paypal_cert_pem
      File.read("#{Rails.root}/certs/#{configatron.paypal.cert_filename.to_s}")
    end

    def app_cert_pem
      File.read("#{Rails.root}/certs/app_cert.pem")
    end

    def app_key_pem
      File.read("#{Rails.root}/certs/app_key.pem")
    end

    def encrypt_for_paypal(values)
      signed = OpenSSL::PKCS7::sign(
        OpenSSL::X509::Certificate.new(app_cert_pem),
        OpenSSL::PKey::RSA.new(app_key_pem, ''),
        values.map { |k, v| "#{k}=#{v}" }.join("\n"), [], OpenSSL::PKCS7::BINARY)
      OpenSSL::PKCS7::encrypt(
        [OpenSSL::X509::Certificate.new(paypal_cert_pem)],
        signed.to_der, OpenSSL::Cipher::Cipher::new("DES3"),
        OpenSSL::PKCS7::BINARY).to_s.gsub("\n", "")
    end
  end
end
