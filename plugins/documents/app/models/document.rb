class Document < ActiveRecord::Base

  belongs_to :user

  validates_presence_of :content

  # @return [String] Content-type, or +nil+ if no valid one found.
  def content_type
    MIME::Types.type_for(name).first.try(:content_type)
  end

end
