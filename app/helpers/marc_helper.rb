module MarcHelper
  DELIM = '|DELIM|'

  def display_marc_field(marc, field_name)
    config = MARC_FIELDS[field_name]

    fail "Field name '#{field_name}' not found in config/marc_display_fields.yml" unless config

    # field_name is a label used to identify a field group in the MARC_FIELDS hash
    #     (maintained in config/marc_display_fields.yml)
    # field_name must begin "subject" for subject heading groups [by convention] so
    #    options[:subject] can be set correctly below
    #
    # each field group is an array of hashes, one for each marc tag in the field group
    # each marc tag hash can have up to 5 keys:
    #     tag               field tag                         required
    #     ind1              first indicator                   optional  default = :all
    #     ind2              second indicator                  optional  default = :all
    #     display           subfield codes to display         optional  default = :all
    #     search            subfield codes to redirect on     optional  default = ''
    #     split             split value for breaking up       optional default = nil
    #                         data in a field [e.g., contents]
    #     require_sf        subfield must be present, and...  optional
    #     require_sf_value  ...must have this value.          optional
    # only keys that vary from the defaults need to be specified in MARC_FIELDS but
    # ind1, ind2 must always be specified together
    #

    out = []

    # loop through elements in the field group
    config.each do |field|
      # set options
      options = {}
      if field.key?('ind1') && field.key?('ind2')
        options[:indicators] = [field['ind1'], field['ind2']]
      end
      if field.key?('search')
        options[:search_subfields] = field['search']
      end
      if field.key?('split')
        options[:split] = field['split']
      end
      if field.key?('require_sf')
        options[:require_sf] = field['require_sf'].to_s
      end
      if field.key?('require_sf_value')
        options[:require_sf_value] = field['require_sf_value'].to_s
      end
      if field_name.match(/^subject/)
        options[:subject] = true
      end
      # process marc tag
      out << clio_get_field_values(marc, field['tag'].to_s, field['display'], options)
    end

    out.flatten
  end

  def clio_get_field_values(marc, tag, display_subfields = :all, options = {})
    options.reverse_merge!(vernacular: true,
                           search_subfields: '',
                           subject: false,
                           indicators: [:all, :all],
                           split: nil,
                           require_sf: nil,
                           require_sf_value: nil)
    # get options
    ind1, ind2  = options[:indicators]
    search_subfields = options[:search_subfields]

    values = []
    marc.each_by_tag(tag) do |field|

      # test for indicators
      next unless ind1 == :all || ind1.include?(field.indicator1)
      next unless ind2 == :all || ind2.include?(field.indicator2)

      # test for required subfield, subfield value
      if options[:require_sf]
        next unless field[ options[:require_sf] ].present?
        next unless field[ options[:require_sf] ] == options[:require_sf_value]
      end

      display = process_field(field, display_subfields, search_subfields, options[:subject])
      unless display.empty?
        options[:split] ? values << display.split(options[:split]) : values << display
      end
      # get matching script field if there is a subfield 6 (watch for missing subfields)
      if options[:vernacular] &&
         field.subfields.first &&
         field.subfields.first.code == '6'
        display = process_vernacular(marc, field, display_subfields, search_subfields, options[:subject])
        unless display.empty?
          options[:split] ? values << display.split(options[:split]) : values << display
        end
      end

    end

    values.flatten
  end

  def process_vernacular(marc, field, display_subfields, search_subfields, subject_option)
    # sequence number from subfield 6
    seq = field.subfields.first.value[4..5]
    display = ''
    # lookup vernacular
    marc.each_by_tag('880') do |t880|
      sub6 = t880.subfields.first
      # sequesnce number match
      if (sub6.code == '6') && (sub6.value[4..5] == seq)
        display = process_field(t880, display_subfields, search_subfields, subject_option)
        # if there is a search field defined, tag the entry
        # currently used to suppress link for author redirection until we can get 880 authors into the author facet
        display += DELIM + 't880' if display.match(/DELIM/)
        break
      end
    end
    display
  end

  def process_field(field, display_subfields, search_subfields, subject_option)
    if subject_option
      display = select_subfields_subject_heading(field, display_subfields)
    else
      display = select_subfields(field, display_subfields)
    end
    # field has search redirection
    # NOTE: subject search redirection uses all subfields and is handled in generate_value_links_subject;
    #       a subject heading should never use the following
    unless display.empty?

      # HTML-escape all MARC data retrieved for display purposes
      display = CGI.escapeHTML(display)

      unless search_subfields.empty?
        search = select_subfields(field, search_subfields)

        # The display field is html-escaped. the search data should be as-is.
        # Combine carefully to avoid rails auto-escaping.
        display = raw("#{display}#{DELIM}#{search}")
      end
    end
    display
  end

  def select_subfields(field, subfields_to_select)
    value = ''
    subflds = field.subfields.select { |sf| subfields_to_select == :all || subfields_to_select.include?(sf.code) }
    unless subflds.empty?
      value = subflds.map { |sf| sf.value }.join(' ')
    end
    value
  end

  def select_subfields_subject_heading(field, subfields_to_select)
    # output subject headings with ' - ' preceeding subfields vxyz
    out = ''
    subflds = field.subfields.select { |sf| subfields_to_select == :all || subfields_to_select.include?(sf.code) }
    unless subflds.empty?
      out = subflds.shift.value
      subflds.each do |s|
        if 'vxyz'.include?(s.code)
          out += ' - ' + s.value
        else
          out += ' ' + s.value
        end
      end
    end
    out
  end

  def display_unlinked_880_field(marc)
    # build display of unlinked 880 fields
    values = []
    marc.each_by_tag('880') do |t880|
      sub6 = t880.subfields.first
      # sequesnce number match 00
      if sub6.present? && (sub6.code == '6') && (sub6.value[4..5] == '00')
        display = process_field(t880, 'abcdefghijklmnopqrstuvwxyz', '', false)
        values << display unless display.empty?
      end
    end
    values.flatten
  end
end
