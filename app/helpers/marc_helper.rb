module MarcHelper
  DELIM = '|DELIM|'.freeze

  # Given the full MARC of a document and a CLIO field-name,
  # - lookup the CLIO config for the field-name,
  # - parse the marc according to the config
  # - return an array of strings for display
  def display_marc_field(marc, field_name)
    config = MARC_FIELDS[field_name]

    raise "Field name '#{field_name}' not found in config/marc_display_fields.yml" unless config

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
      options[:search_subfields] = field['search'] if field.key?('search')
      options[:split] = field['split'] if field.key?('split')
      if field.key?('require_sf')
        options[:require_sf] = field['require_sf'].to_s
      end
      if field.key?('require_sf_value')
        options[:require_sf_value] = field['require_sf_value'].to_s
      end
      options[:subject] = true if field_name =~ /^subject/
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
    ind1, ind2 = options[:indicators]
    search_subfields = options[:search_subfields]

    values = []
    marc.each_by_tag(tag) do |field|
      # test for indicators
      next unless ind1 == :all || ind1.include?(field.indicator1)
      next unless ind2 == :all || ind2.include?(field.indicator2)

      # test for required subfield, subfield value
      if options[:require_sf]
        next unless field[options[:require_sf]].present?
        next unless field[options[:require_sf]] == options[:require_sf_value]
      end

      display = process_field(field, display_subfields, search_subfields, options[:subject])
      unless display.empty?
        values << (options[:split] ? display.split(options[:split]) : display)
      end
      # get matching script field if there is a subfield 6 (watch for missing subfields)
      if options[:vernacular] &&
         field.subfields.first &&
         field.subfields.first.code == '6'
        display = process_vernacular(marc, field, display_subfields, search_subfields, options[:subject])
        unless display.empty?
          values << (options[:split] ? display.split(options[:split]) : display)
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
      # sequence number match
      next unless (sub6.code == '6') && (sub6.value[4..5] == seq)
      display = process_field(t880, display_subfields, search_subfields, subject_option)
      # Tag as vernacular if there's a search field, or if we're in a subject field
      display += DELIM + 't880' if display =~ /DELIM/ || subject_option
      break
    end
    display
  end

  def process_field(field, display_subfields, search_subfields, subject_option)
    display = if subject_option
                select_subfields_subject_heading(field, display_subfields)
              else
                select_subfields(field, display_subfields)
              end
    # field has search redirection
    # NOTE: subject search redirection uses all subfields and is handled in generate_value_links_subject;
    #       a subject heading should never use the following
    if display.present?

      # HTML-escape all MARC data retrieved for display purposes
      display = CGI.escapeHTML(display)

      if search_subfields.present?
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
    value = subflds.map(&:value).join(' ') unless subflds.empty?
    value
  end

  def select_subfields_subject_heading(field, subfields_to_select)
    # output subject headings with ' - ' preceeding subfields vxyz
    out = ''
    subflds = field.subfields.select { |sf| subfields_to_select == :all || subfields_to_select.include?(sf.code) }
    unless subflds.empty?
      out = subflds.shift.value
      subflds.each do |s|
        # NEXT-1672 - split on Title of Work as well
        # splitable_subfields = 'vxyz'
        splitable_subfields = 'tvxyz'
        out += if splitable_subfields.include?(s.code)
                 ' - ' + s.value
               else
                 ' ' + s.value
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
