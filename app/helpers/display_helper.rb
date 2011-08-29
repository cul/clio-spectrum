module DisplayHelper

  def render_first_available_partial(partials, options)
    partials.each do |partial|
      begin
        return render(:partial => partial, :locals => options)
      rescue ActionView::MissingTemplate 
        next
      end
    end

    raise "No partials found from #{partials.inspect}" 


  end

  def render_documents(documents, options)
    partial = "/_display/#{options[:action]}/#{options[:view_style]}"
    render partial, { :documents => documents.listify}

  end

  def render_document_view(document, options = {})
    template = options.delete(:template) || raise("Must specify template")
    formats = determine_formats(document, options.delete(:format))

    partial_list = formats.collect { |format| "/_formats/#{format}/#{template}"}
    render_first_available_partial(partial_list, options.merge(:document => document))


  end 

  SOLR_FORMAT_LIST = {
    "Music - Recording" => "music_recording",
    "Music - Score" => "music"
  }

  FORMAT_RANKINGS = ["music_recording", "music", "clio", "ebooks", "article", "lweb"]

  def determine_formats(document, defaults = [])
    formats = defaults.listify
    if document.kind_of?(SolrDocument)
      formats << "clio"

      document["format"].each do |format|
        formats << SOLR_FORMAT_LIST[format] if SOLR_FORMAT_LIST[format]
      end
    end

    formats.sort { |x,y| FORMAT_RANKINGS.index(x) <=> FORMAT_RANKINGS.index(y) }
  end


  def generate_value_links(values, category)

    # search value the same as the display value

    values.listify.collect do |v|
      case category
      when :author
        link_to(v, url_for(:controller => "catalog", :action => "index", :q => v, :search_field => "author", :commit => "search"))
      when :subject
        link_to(v, url_for(:controller => "catalog", :action => "index", :q => v, :search_field => "subject", :commit => "search"))
      when :topic
        link_to(v, url_for(:controller => :catalog, :action => :index, "f[subject_topic_facet][]" => v))


      else
        raise "invalid category specified for generate_value_links"
      end
    end
  end

  def generate_value_links_2(values, category)

    # search value differs from display value
    # values is array of arrays; [display, search]

    values.collect do |v|
      
      s = v.split("|DELIM|")
      
      case category
      when :author
        link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "author", :commit => "search"))
      when :subject
        link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "subject", :commit => "search"))
      when :title
        link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "title", :commit => "search"))

      else
        raise "invalid category specified for generate_value_links"
      end
    end
  end

  def get_marc_values(marc, tag, display_subfields = :all,  options = {})
    options.reverse_merge!({ :vernacular => true,
                              :subject => false,
                              :indicators => [:all, :all]
      })
      
    values = []
    ind1,ind2  = options[:indicators]
    marc.each_by_tag(tag) do |v| 
      # test for indicators
      if (ind1 == :all || ind1.include?(v.indicator1)) && (ind2 == :all || ind2.include?(v.indicator2))
        
        if options[:subject]
          values << format_subject_heading(v,display_subfields)
        else
          values << v.subfields.select { |sf| display_subfields == :all || display_subfields.include?(sf.code) }.collect(&:value).join(' ')
        end
      
        if options[:vernacular]
          if v.subfields.first.code == "6"
            # sequence number from subfield 6
            seq = v.subfields.first.value[4..5]
            # lookup vernacular
            marc.each_by_tag('880') do |t880|
              subflds = t880.subfields
              # sequesnce number match
              if (subflds.first.code == "6") && (subflds.first.value[4..5] == seq)
                if options[:subject]
                  values << format_subject_heading(t880,display_subfields)
                else
                  values << subflds.select { |sf| display_subfields == :all || display_subfields.include?(sf.code) }.collect(&:value).join(' ')
                end
              end
            end
          end
        end
      end
    end
    
    values
  end

  # for heading redirects: if search subfields are not the same as display subfields
  def get_marc_values_2(marc, field, display_subfields = :all, search_subfields = :all, options = {})
    options.reverse_merge!({ :vernacular => true,
                              :indicators => [:all, :all]
      })
      
    values = []
    ind1,ind2  = options[:indicators]
    marc.each_by_tag(field) do |fld| 
      # test for indicators
      if (ind1 == :all || ind1.include?(fld.indicator1)) && (ind2 == :all || ind2.include?(fld.indicator2))
        
        display = fld.subfields.select { |sf| display_subfields == :all || display_subfields.include?(sf.code) }.collect(&:value).join(' ')
        search  = fld.subfields.select { |sf| search_subfields == :all || search_subfields.include?(sf.code) }.collect(&:value).join(' ')
        values << display + "|DELIM|" + search
      
        if options[:vernacular]
          if fld.subfields.first.code == "6"
            # sequence number from subfield 6
            seq = fld.subfields.first.value[4..5]
            # lookup vernacular
            marc.each_by_tag('880') do |t880|
              subflds = t880.subfields
              # sequesnce number match
              if (subflds.first.code == "6") && (subflds.first.value[4..5] == seq)
                display = subflds.select { |sf| display_subfields == :all || display_subfields.include?(sf.code) }.collect(&:value).join(' ')
                search  = subflds.select { |sf| search_subfields == :all || search_subfields.include?(sf.code) }.collect(&:value).join(' ')
                values << display + "|DELIM|" + search
              end
            end
          end
        end
      end
    end
    
    values
  end

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

  def add_row(title, value, options = {})
    options.reverse_merge!( {
      :display_blank => false,
      :display_only_first => false,
      :join => nil,
      :abbreviate => nil,
      :html_safe => true,
      :style => :definition
    })

    values = value.listify

    values = values.collect { |txt| txt.to_s.abbreviate(options[:abbreviate]) } if options[:abbreviate]
    value_txt = if options[:display_only_first] 
                  values.first.to_s 
                elsif options[:join]
                  values.join(options[:join]).to_s 
                else
                  values.collect { |v| content_tag(:div, v.to_s, :class => "entry") }.join("")
                end

    value_txt = value_txt.html_safe if options[:html_safe]  
    result = ""
    if options[:display_blank] || !value_txt.empty?

      result = content_tag(:div, :class => "row") do
        if options[:style] == :definition
          content_tag(:div, title.to_s, :class => "label") + content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "value")
        elsif options[:style] == :blockquote
          content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "blockquote")
        end

      end

    end

    result
  end
  
  def get_author(marc)
    
    # only one of these will appear in a record
    
    data = get_marc_values_2(marc, '100', 'abcdefgklnpqtu', 'acqd')
    data = get_marc_values_2(marc, '110', 'abcdefgklnptu', 'ab') if data.empty?
    data = get_marc_values_2(marc, '111', 'acdefgklnpqtu', 'a') if data.empty?
    data
    
  end

  def get_author_other(marc)
  
    data = []
    data << get_marc_values_2(marc, '700', 'abcdefghlmnopqrstu', 'acqd')
    data << get_marc_values_2(marc, '710', 'abcdefghklmnoprstu', 'ab')
    data << get_marc_values_2(marc, '711', 'acdefghklnpqstu', 'a')
    data.flatten
    
  end
    
  def get_description(marc)
    
    data = []
    data << get_marc_values(marc, '300', 'abcefg3')
    data << get_marc_values(marc, '305', 'abcdefmn')
    data << get_marc_values(marc, '308', 'abcdef')
    data << get_marc_values(marc, '340', 'abcdefhi')
    data.flatten
    
  end

  def get_ISN(marc)
  
    data = []
    data << get_marc_values(marc, '020', 'ac')
    data << get_marc_values(marc, '022', 'a')
    data << get_marc_values(marc, '024', 'ac')
    data.flatten
    
  end
  
  def get_notes(marc)
  
    data = []
    data << get_marc_values(marc, '037', 'abcdefgh')
    data << get_marc_values(marc, '254', 'a')
    data << get_marc_values(marc, '307', 'ab')
    data << get_marc_values(marc, '500', 'a')
    data << get_marc_values(marc, '501', 'a')
    data << get_marc_values(marc, '502', 'a')
    data << get_marc_values(marc, '503', 'a')
    data << get_marc_values(marc, '504', 'ab')
    data << get_marc_values(marc, '508', 'a')
    data << get_marc_values(marc, '513', 'ab')
    data << get_marc_values(marc, '515', 'a')
    data << get_marc_values(marc, '518', 'a3')
    data << get_marc_values(marc, '521', 'ab3')
    data << get_marc_values(marc, '522', 'a')
    data << get_marc_values(marc, '523', 'ab')
    data << get_marc_values(marc, '525', 'a')
    data << get_marc_values(marc, '527', 'a')
    data << get_marc_values(marc, '530', 'abcd3')
    data << get_marc_values(marc, '534', 'abcefklmnopt')
    data << get_marc_values(marc, '535', 'abcdg3')
    data << get_marc_values(marc, '537', 'a')
    data << get_marc_values(marc, '547', 'a')
    data << get_marc_values(marc, '550', 'a')
    data << get_marc_values(marc, '556', 'a')
    data << get_marc_values(marc, '565', 'abcde3')
    data << get_marc_values(marc, '567', 'a')
    data << get_marc_values(marc, '580', 'a')
    data << get_marc_values(marc, '581', 'a3')
    data << get_marc_values(marc, '582', 'a')
    data << get_marc_values(marc, '584', 'ab')
    data << get_marc_values(marc, '586', 'a3')
    data << get_marc_values(marc, '590', 'a')
    data.flatten
    
  end

  def get_publisher(marc)
  
    data = []
    data << get_marc_values(marc, '260', 'abcefg3')
    data << get_marc_values(marc, '261', 'abdef')
    data << get_marc_values(marc, '262', 'abckl')
    data << get_marc_values(marc, '270', 'abcdefghijklmnpqrz')
    data << get_marc_values(marc, '362', 'a')
    data.flatten
  
  end
  
  def get_series(marc)
  
    data = []
    data << get_marc_values(marc, '800', 'abcdefghklmnopqrstuv3')
    data << get_marc_values(marc, '810', 'abcdefghklmnoprstuv3')
    data << get_marc_values(marc, '811', 'acdefghklnpqstuv3')
    data << get_marc_values(marc, '830', 'adfghklmnoprstv3')
    data << get_marc_values(marc, '840', 'ahv')
    data.flatten
    
  end
  
  def get_subject_LC(marc)
    
    data = []
    data << get_marc_values(marc, '600', 'abcdefghklmnopqrstuvxyz', options = {:indicators => [:all, '0'], :subject => true})
    data << get_marc_values(marc, '610', 'abcdefghklmnoqrstuvxyz', options = {:indicators => [:all, '0'], :subject => true})
    data << get_marc_values(marc, '611', 'acdefghklnpqstuvxyz', options = {:indicators => [:all, '0'], :subject => true})
    data << get_marc_values(marc, '630', 'adfghklmnoprstvxyz', options = {:indicators => [:all, '0'], :subject => true})    
    data << get_marc_values(marc, '650', 'abcdvxyz', options = {:indicators => [:all, '0'], :subject => true})
    data << get_marc_values(marc, '651', 'avxyz', options = {:indicators => [:all, '0'], :subject => true})
    
    data.flatten

  end
  
  def get_title_other(marc)
    
    data = []
    data << get_marc_values(marc, '246', 'abfghinp', options = {:indicators => ['01', ' 3']})
    data << get_marc_values(marc, '247', 'abfghnp')
    data << get_marc_values(marc, '730', 'adfghklmnoprst')
    data << get_marc_values(marc, '740', 'ahnp')
    
    data.flatten
    
  end
  
  def get_title_uniform(marc)
    
    # only one of these will appear in a record

    data = get_marc_values(marc, '240', 'adfghklmnoprs')
    data = get_marc_values(marc, '130', 'adfghklmnoprst') if data.empty?
    data

  end
  
end
