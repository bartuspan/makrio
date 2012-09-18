class ActsAsTaggableOn::Tag
  attr_accessible :description
  include PgSearch
  pg_search_scope :search_by_name, :against => :name

  def self.possible_duplicates
    self.all.map do |x|
      next if x.name == x.name.parameterize
      if(ActsAsTaggableOn::Tag.where(:name => x.name.parameterize).count > 0)
        x.name
      end
    end.compact
  end

  def self.delete_empty_tags
    self.all.map do |x|
      if x.taggings.count == 0
        x.destroy
      end
    end
  end

  def as_json(opts={})
    {
      :name => name,
      :display_name => display_name
    }
  end

  def display_name
    name.titleize
  end

  def self.combine_tags(tag_to_delete, opts)
    new_home = opts[:into]
    dying_tag = ActsAsTaggableOn::Tag.find_by_name(tag_to_delete)
    new_tag = ActsAsTaggableOn::Tag.find_by_name(new_home)
    dying_tag.taggings.each do |tagging|
      tagging.update_attribute(:tag_id, new_tag.id)
    end
  end

  def most_popular_post
    StatusMessage.with_screenshot.tagged_with(self.name).order('likes_count desc').first
  end

  def followed_count
   @followed_count ||= TagFollowing.where(:tag_id => self.id).count
  end

  def self.tag_text_regexp
    @@tag_text_regexp ||= (RUBY_VERSION.include?('1.9') ? "[[:alnum:]]_-" : "\\w-")
  end

  def self.autocomplete(name)
    where("name LIKE ?", "#{name.downcase}%")
  end

  def self.normalize(name)
    if name =~ /^#?<3/
      # Special case for love, because the world needs more love.
      '<3'
    elsif name
      name.gsub(/[^#{self.tag_text_regexp}]/, '').downcase
    end
  end
end
