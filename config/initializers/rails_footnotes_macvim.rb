if Rails.env.development?
  Footnotes::Filter.prefix = 'mvim://open?url=file://%s&amp;line=%d&amp;column=%d'
end
