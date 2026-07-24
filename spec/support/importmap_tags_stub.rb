# frozen_string_literal: true

module ImportmapTagsStub
  def javascript_importmap_tags
    ""
  end
end

ActionView::Base.include(ImportmapTagsStub)
