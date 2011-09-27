module MarcHelper

  DELIM = "|DELIM|"

  def display_marc_field(marc, field_name)
    config = MARC_FIELDS[field_name]
    
    raise "Field name not found in config/marc_display_fields.yml" unless config
    
    # field_name is a label used to identify a field group in the MARC_FIELDS hash
    # field_name must begin "subject" for subject heading groups [by convention] so
    #    options[:subject] can be set correctly below
    #
    # each field group is an array of hashes, one for each marc tag in the field group
    # each marc tag hash can have up to 5 keys:
    #     tag         field tag                         required
    #     ind1        first indicator                   optional  default = :all
    #     ind2        second indicator                  optional  default = :all
    #     display     subfield codes to display         optional  default = :all
    #     search      subfield codes to redirect on     optional  default = ''
    # only keys that vary from the defaults need to be specified in MARC_FIELDS
    #
    
    out = []
    
    # loop through elements in the field group
    config.each do |field|
      # set options
      options = {}
      if field.has_key?('ind1') && field.has_key?('ind2')
        options[:indicators] = [ field['ind1'], field['ind2'] ]
      end
      if field.has_key?('search')
        options[:search_subfields] = field['search']
      end
      if field_name.match(/^subject/)
        options[:subject] = true
      end
      # process marc tag
      out << get_field_values(marc, field["tag"].to_s, field["display"], options)
    end
    
    out.flatten
    
  end

  def get_field_values(marc, tag, display_subfields = :all, options = {})
    options.reverse_merge!({  :vernacular => true,
                              :search_subfields => '',
                              :subject => false,
                              :indicators => [:all, :all] })
    # get options
    ind1,ind2  = options[:indicators]
    search_subfields = options[:search_subfields]

    values = []
    marc.each_by_tag(tag) do |field|
      # test for indicators
      if (ind1 == :all || ind1.include?(field.indicator1)) && (ind2 == :all || ind2.include?(field.indicator2))
        if options[:subject]
          display = select_subfields_subject_heading(field,display_subfields)
        else
          display = select_subfields(field,display_subfields)
        end
        # field has search redirection
        # NOTE: subject search redirection uses all subfields and is handled in generate_value_links_subject;
        #       a subject heading should never use the following
        unless search_subfields.empty?
          search = select_subfields(field, search_subfields)
          display += DELIM + search
        end
        values << display
        
        # get matching script field if there is a subfield 6
        if options[:vernacular] && field.subfields.first.code == "6"
          values << process_vernacular(marc, field, display_subfields, search_subfields, options[:subject])
        end
      end
    end
    
    values
  
  end
  
  def select_subfields(field, subfields_to_select)
    
    subflds = field.subfields.select { |sf| subfields_to_select == :all || subfields_to_select.include?(sf.code) }
    subflds.collect { |sf| sf.value}.join(' ')
    
  end

  def select_subfields_subject_heading(field,subfields_to_select)
    
    # output subject headings with ' - ' preceeding subfields vxyz
    
    subflds = field.subfields.select { |sf| subfields_to_select == :all || subfields_to_select.include?(sf.code) }
    out = subflds.shift.value
    subflds.each do |s|
      if 'vxyz'.include?(s.code)
        out += ' - ' + s.value
      else
        out += ' ' + s.value
      end
    end
    out
  end

  def process_vernacular(marc, field, display_subfields, search_subfields, subject_option)
    
    # sequence number from subfield 6
    seq = field.subfields.first.value[4..5]
    # lookup vernacular
    marc.each_by_tag('880') do |t880|
      sub6 = t880.subfields.first
      # sequesnce number match
      if (sub6.code == "6") && (sub6.value[4..5] == seq)
        if subject_option
          display = select_subfields_subject_heading(t880, display_subfields)
        else
          display = select_subfields(t880, display_subfields)
        end
        # field has search redirection
        # NOTE: subject search redirection uses all subfields and is specially handled in generate_value_links_subject;
        #       a subject heading should never use the following
        unless search_subfields.empty?
          search = select_subfields(t880, search_subfields)
          display += DELIM + search
        end
        return display
      end
    end

  end

end
