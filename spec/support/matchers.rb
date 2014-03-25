
RSpec::Matchers.define :contain_in_fields do |target, *field_list|
  match do |doc|
    targets = Array.wrap(target).map { |t| Regexp.new(t.gsub(/ +/, '.*')) }
    field_list.any? { |field_name| targets.any? { |t| t.match(doc.get(field_name)) } }
  end

  failure_message_for_should do |doc|
    doc_data = field_list.map do |field_name|
      "#{field_name}=#{ doc.get(field_name) }"
    end.join(', ')
    "expected that #{target} would be contained in doc fields (#{doc_data})"
  end

end
