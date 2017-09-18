module TrajectUtility

  NUM_ALPHA = ('0'..'9').to_a + ('a'..'z').to_a
  MAX_INDEX = NUM_ALPHA.size - 1
  MAP = NUM_ALPHA.index_by{ |char| NUM_ALPHA[MAX_INDEX - NUM_ALPHA.index(char)] }

  def self.reverseString(string)
    # fold diacritics back to ascii
    string = ActiveSupport::Inflector.transliterate(string)

    # pad out to 50 characters with trailing tildes
    # (why?  don't know, mimicking beanshell implementation,
    #  could be just java implementation quirk)
    if string.length < 50
      string = (string + ('~' * 50))[0...50]
    end

    (0 ... string.length).map { |i|
      reverseLetter( string[i] )
    }.join

  end

  def self.reverseLetter(letter)

    case letter
    when /\p{Alnum}/
      MAP[letter]
    when '.'
      '}'
    when /\{|\||\}/
      ' '
    else
      '~'
    end

  end

  def self.location_code_to_label(code)
    return '' unless code
    case code
    # Princeton
    when 'scsbpul'
      return 'ReCAP Shared Collection (Princeton)'
    when 'scsb-pul'
      return 'ReCAP Shared Collection (Princeton)'
    # NYPL
    when 'scsbnypl'
      return 'ReCAP Shared Collection (NYPL)'
    when 'scsb-nypl'
      return 'ReCAP Shared Collection (NYPL)'
    end
    return ''
  end

end

