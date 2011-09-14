module MarcHelper

  DELIM = "|DELIM|"

  def display_marc_field(marc, field_name)
    config = MARC_FIELDS[field_name]
    
    raise "Field name not found in config/marc_display_fields.yml" unless config
    
    out = []
    
    config.each do |field|
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
      out << get_field_values(marc, field["tag"].to_s, field["display"], options)
    end
    
    out.flatten
    
  end

  def get_field_values(marc, tag, display_subfields = :all, options = {})
    options.reverse_merge!({  :vernacular => true,
                              :search_subfields => '',
                              :subject => false,
                              :indicators => [:all, :all] })
    
    values = []
    ind1,ind2  = options[:indicators]
    search_subfields = options[:search_subfields]
    marc.each_by_tag(tag) do |field|
      # test for indicators
      if (ind1 == :all || ind1.include?(field.indicator1)) && (ind2 == :all || ind2.include?(field.indicator2))
        if options[:subject]
          display = format_subject_heading(field,display_subfields)
        else
          display = field.subfields.select { |sf| display_subfields == :all || display_subfields.include?(sf.code) }.collect(&:value).join(' ')
        end
        # field has search redirection
        unless search_subfields.empty?
          search = field.subfields.select { |sf| search_subfields == :all || search_subfields.include?(sf.code) }.collect(&:value).join(' ')
          display += DELIM + search
        end
        values << display
        
        
        
        
      end
    end
    
    values
  
  end
  




  # if options[:subject]
  #   values << format_subject_heading(fld,display_subfields)
  # else
  #   values << fld.subfields.select { |sf| display_subfields == :all || display_subfields.include?(sf.code) }.collect(&:value).join(' ')
  # end
  # 
  # def get_values(marc, tag, display_subfields = :all, search_subfields = :all, options = {})
  #   options.reverse_merge!({ :vernacular => true,
  #                             :subject => false,
  #                             :indicators => [:all, :all]
  #                             })
  #     
  #   values = []
  #   ind1,ind2  = options[:indicators]
  #   marc.each_by_tag(tag) do |fld| 
  #     # test for indicators
  #     if (ind1 == :all || ind1.include?(fld.indicator1)) && (ind2 == :all || ind2.include?(fld.indicator2))
  #       
  #       display = fld.subfields.select { |sf| display_subfields == :all || display_subfields.include?(sf.code) }.collect(&:value).join(' ')
  #       search  = fld.subfields.select { |sf| search_subfields == :all || search_subfields.include?(sf.code) }.collect(&:value).join(' ')
  #       values << display + DELIM + search
  #     
  #       if options[:vernacular]
  #         if fld.subfields.first.code == "6"
  #           # sequence number from subfield 6
  #           seq = fld.subfields.first.value[4..5]
  #           # lookup vernacular
  #           marc.each_by_tag('880') do |t880|
  #             subflds = t880.subfields
  #             # sequesnce number match
  #             if (subflds.first.code == "6") && (subflds.first.value[4..5] == seq)
  #               display = subflds.select { |sf| display_subfields == :all || display_subfields.include?(sf.code) }.collect(&:value).join(' ')
  #               search  = subflds.select { |sf| search_subfields == :all || search_subfields.include?(sf.code) }.collect(&:value).join(' ')
  #               values << display + DELIM + search
  #             end
  #           end
  #         end
  #       end
  #     end
  #   end
  #   
  #   values
  # end
  # 

  def format_subject_heading(field,display_subfields)
    subflds = field.subfields.select { |sf| display_subfields == :all || display_subfields.include?(sf.code) }
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



end
