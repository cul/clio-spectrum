
RSpec::Matchers.define :contain_in_fields do |target, *field_list|
  match do |doc|
    field_list.reduce(false) do |determination, field_name|
      target_as_regexp = Regexp.new( target.gsub(/ +/, '.*') )
      determination = determination or target_as_regexp.match( doc.get(field_name) )
    end
  end
  
  failure_message_for_should do |doc|
    doc_data = field_list.map do |field_name|
      "#{field_name}=#{ doc.get(field_name) }"
    end.join(', ')
    "expected that #{target} would be contained in doc fields (#{doc_data})"
  end
  
end
