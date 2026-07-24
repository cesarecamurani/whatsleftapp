# frozen_string_literal: true

require "uri"

class RecipeImageUrlResolver
  MEREDITH_IMAGE_SERVICE_HOST = "imagesvc.meredithcorp.io"

  def self.call(url)
    new(url).call
  end

  def initialize(url)
    @url = url
  end

  def call
    return if url.blank?
    return url unless meredith_proxy_url?

    embedded_url.presence || url
  end

  private

  attr_reader :url

  def meredith_proxy_url?
    uri.host == MEREDITH_IMAGE_SERVICE_HOST
  rescue URI::InvalidURIError
    false
  end

  def embedded_url
    return if uri.query.blank?

    query_params = URI.decode_www_form(uri.query).to_h

    query_params["url"]
  end

  def uri
    @uri ||= URI.parse(url)
  end
end
