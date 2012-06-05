class TrialTag
  include ComfortableMexicanSofa::Tag

  # We use the identifier differently here that in the other CMS Tags, Those tags
  # creates a block with the identifier matching by this expression. It does that
  # by magic calling "block". The "block" method does not seem to get called
  # anywhere else in CMS, other than tests, so it's probably safe to do this.
  # As long as we don't cause the 'block' method to be called then a page block
  # will not get created with the matched identifier.
  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    # Need to make sure that the identifier is match[1] using (?:xxx) to avoid capture.
    /\{\{\s*cms:trial(?::(#{identifier}))?\s*\}\}/
  end

  def content
    case identifier
      when "name"
        @trail.name
      when "page"
        "<%= render :partial => 'trials/index' %>"
      when nil
        "<%= render :partial => 'trials/index' %>"
      else
        "<%= render :partial => 'trials/#{identifier}' %>"
    end
  end
end