module PersonName
  def self.normalize(value)
    I18n.transliterate(value.to_s).squish.upcase
  end
end
