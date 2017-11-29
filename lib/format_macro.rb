module FormatMacro

  # shortcut
  Marc21 = Traject::Macros::Marc21

  FORMAT_ORDER = [
    :book, :score, :map, :mss, :video, :sound, :music, :image, 
    :data, :prog, :serial, :news, :lleaf, 
    :usdoc, :nydoc, :conf, :thesis, :micro, :art, :other, :online
  ].freeze

  FORMAT_LABELS = {
    book:   'Book',
    data:   'Computer File',
    prog:   'Computer Program',
    conf:   'Conference Proceedings',
    image:  'Image',
    serial: 'Journal/Periodical',
    lleaf:  'Loose-leaf',
    mss:    'Manuscript/Archive',
    map:    'Map/Globe',
    micro:  'Microformat',
    music:  'Music - Recording',
    score:  'Music - Score',
    news:   'Newspaper',
    online: 'Online',
    other:  'Other',
    sound:  'Audio Recording (Non-musical)',
    thesis: 'Thesis',
    video:  'Video',
    usdoc:  'US Government Document',
    nydoc:  'NY State/City Government Document',
    art:    'Art Work (Original)'
  }.freeze



  def columbia_format()
    return lambda do |record, accumulator, context|
      # accumulate format values
      formats = Array.new
      
      # pull out the field values we need
      leader06 = record.leader.byteslice(6)
      leader07 = record.leader.byteslice(7)
      f006 = Marc21.extract_marc_from(record, '006')
      f007 = Marc21.extract_marc_from(record, '007')
      # control field 008 is non-repeatable, but this call returns an array
      f008 = Marc21.extract_marc_from(record, '008').first
      f245h = Marc21.extract_marc_from(record, '245h')
      f502 = Marc21.extract_marc_from(record, '502')
      
      # Branch on leader 06, 'Type of record'
      case leader06
      # a == Language material
      when /a/ 
        # for language material, consider leader 07, 'Bibliographic level'
        case leader07
        when /[acdm]/
          formats << :book
        when /b/
          formats << :serial
        when /i/
          if f008 && f008[21] == 'l'
            formats << :serial
            formats << :lleaf
          end
        end
      when /[bp]/
        formats << :mss
      when /[cd]/
        formats << :score
      when /[ef]/
        formats << :map
      when /g/
        if f008 && f008[33] && 'mv'.include?( f008[33] )
          formats << :video
        end
      when /i/
        formats << :sound
      when /j/
        formats << :music
      when /k/
        if f008 && f008[33] == 'a'
          formats << :art
        end
        if f008 && f008[33] && 'ciklnoz'.include?( f008[33] )
          formats << :image
        end
      when /m/
        if f008.present?
          if f008 && f008[26] == 'b'
            formats << :prog
          else
            formats << :data
          end
        end
      when /o/
        formats << :other
      when /r/
        if f008 && f008[33] == 'a'
          formats << :art
        else
          formats << :other
        end
      when /t/
        case leader07
        when /[am]/
          formats << :book
        when /[cd]/
          formats << :mss
        end
      end

      # What passes through the above filter without a format assignment:
      #  * 'ai' unless type = 'l' (loose-leafs)
      #  * 'as' (all language materials serials)
      #  * 'g' unless type = 'm' or 'v' (films or videos)
      #  * 'k' unless type is one of these: c i k l n o z (images) or type = a (original art)
      #  * 'tb', 'ti', 'ts'

      ## check for serials if no format has been set up to now
      if formats.empty? && leader07 == 's'&& f008.present?
        type = f008[21]
        if type && ' mnp|'.include?(type)
          formats << :serial
        end
        if type == 'n'
          formats << :news
        end
      end

      ## check for serial from 006 if no format has been set up to now
      if formats.empty?
        f006.each do |this006|
          next unless this006[0] == 's'
          type = this006[4]
          if type && ' mnp|'.include?(type)
            formats << :serial
          end
          if type == 'n'
            formats << :news
          end
        end
      end

      ## set online / microformats
      f007.each do |this007|
        if this007.starts_with? 'cr'
          formats << :online
          formats.delete(:data)
          break
        end
        if this007.starts_with? 'h'
          formats << :micro
          break
        end
      end

      ## government documents
      #  formats with gov doc codes
      if leader06 && 'aefgkmort'.include?(leader06)
        if f008.present?
          gdcode = f008[28] || '-'
          cpcode = f008[15..17] || '---'
          # federal document published in US
          if gdcode == 'f' && cpcode[2] == 'u'
            formats << :usdoc
          # local or state document published in New York
          elsif 'clmos'.include?(gdcode) && cpcode =='nyu'
            # complex logic, hide within method
            f260b = Marc21.extract_marc_from(record, '260b')
            f264b = Marc21.extract_marc_from(record, '264b')
            
            formats << :nydoc if FormatMacro.isNYgovdoc?(f260b, f264b)
          end
        end
      end

      ## conference proceedings
      # if Traject::Macros::MarcFormatClassifier.new(record).proceeding?
      #   formats << :conf
      # end
      record.find do |field|
        next unless field.tag.slice(0) == '6'
        field.subfields.find do |subfield| 
          next unless 'xv'.include?(subfield.code) 
          if subfield.value.match(/congresses/i)
            formats << :conf
            break
          end
        end
      end

      ## thesis
      if f502.present?
        formats << :thesis
      end

      ## microforms / manuscripts
      if f245h.present?
        f245h.each do |medium|
          if medium.match(/microform/i)
            formats << :micro
          elsif medium.match(/manuscript/i)
            formats << :mss
          end
        end
      end

      ## default if no formats by now
      formats << :other if formats.empty?

      # TODO:  sort
      formats.uniq.each do |format|
        accumulator << FORMAT_LABELS[format]
      end

    end
  end


  def self.isNYgovdoc?(f260b, f264b)
    publishers = []
    
    f260b.each do |field|
      publishers << field.downcase
    end

    f264b.each do |field|
      publishers << field.downcase
    end

    return true if publishers.empty?
    
    publishers.each do |publisher|
      # Not govdoc if any of these words found
      return false if publisher.match /press/        
      return false if publisher.match /university/        
      return false if publisher.match /library/        
      return false if publisher.match /museum/        
      return false if publisher.match /school/        
      return false if publisher.match /conference/        
      return false if publisher.match /hospital/        
      return false if publisher.match /united nations/       
      return false if publisher.match /text studies/       
      #  Not govdoc if name begins with any of these
      return false if publisher.starts_with? 'american' 
      return false if publisher.starts_with? 'new york agricultural experiment' 
      return false if publisher.starts_with? 'excelsior edition' 
      return false if publisher.starts_with? 'center for medieval' 
      return false if publisher.starts_with? 'wiley' 
      return false if publisher.starts_with? 'springer' 
      return false if publisher.starts_with? 'praeger' 
      return false if publisher.starts_with? 'penguin' 
      return false if publisher.starts_with? 'elsevier' 
      return false if publisher.starts_with? 'bantam' 
    end
    
    return true    
  end


end




# Original Perl source code below



# package Utils::CLIO_formats;
# 
# use strict;
# use warnings;
# 
# ## 2015.03.02 GB -- NEXT-892 update "sound"
# #                   'Sound Recording' --> 'Audio Recording (Non-musical)'
# ## 2015.04.30 GB -- Add facets for US and NYS/NYC government documents
# ## 2016.04.05 GB -- Add facet for original art works
# 
# BEGIN {
#     require Exporter;
#     our $VERSION = 1.00;
#     our @ISA = qw(Exporter);
#     our @EXPORT = qw(setFormat);
# }
# 
# my @format_order = (qw/book score map mss video sound music image data prog serial news lleaf usdoc nydoc conf thesis micro art other online/);
# 
# my %format_labels = (
#          book => 'Book',
#          data => 'Computer File',
#          prog => 'Computer Program',
#          conf => 'Conference Proceedings',
#          image => 'Image',
#          serial => 'Journal/Periodical',
#          lleaf => 'Loose-leaf',
#          mss => 'Manuscript/Archive',
#          map => 'Map/Globe',
#          micro => 'Microformat',
#          music => 'Music - Recording',
#          score => 'Music - Score',
#          news => 'Newspaper',
#          online => 'Online',
#          other => 'Other',
#          sound => 'Audio Recording (Non-musical)',
#          thesis => 'Thesis',
#          video => 'Video',
#          usdoc => 'US Government Document',
#          nydoc => 'NY State/City Government Document',
#          art => 'Art Work (Original)'
#          );
# 
# sub setFormat {
# 
#     my $rec = shift;
# 
#     my %formats = (
#        book   => 0,
#        mss    => 0,
#        score  => 0,
#        map    => 0,
#        video  => 0,
#        sound  => 0,
#        music  => 0,
#        image  => 0,
#        data   => 0,
#        prog   => 0,
#        other  => 0,
#        serial => 0,
#        news   => 0,
#        online => 0,
#        conf   => 0,
#        thesis => 0,
#        micro  => 0,
#        lleaf  => 0,
#        usdoc  => 0,
#        nydoc  => 0,
#        art    => 0
#        );
# 
#     my $leader = $rec->leader();
#     my $ldr6 = substr($leader,6,1);
#     my $ldr7 = substr($leader,7,1);
#     my $t008data = '';
#     if (my $t008 = $rec->field('008')) {
#   $t008data = $t008->data();
#     }
#     
#     # ldr6 values : a [b] c d e f g i j k m o p r t
#     # ldr7 values : a b c d i m s
#     # type of material codes:
#     #   $type = substr($t008data,21,1) if (($ldr6 eq 'a') && ($ldr7 =~ /[bis]/));
#     #   $type = substr($t008data,25,1) if ($ldr6 =~ /[ef]/);
#     #   $type = substr($t008data,26,1) if ($ldr6 eq 'm');
#     #   $type = substr($t008data,33,1) if ($ldr6 =~ /[gkor]/);
#     # form of item codes:
#     #   if ($ldr6 =~ /[efgkor]/) {
#     #       $form = substr($t008data,29,1);
#     #   } else {
#     #       $form = substr($t008data,23,1);
#     #   }
# 
# 
#   CASE: {
#       if ($ldr6 =~ /[a]/) {
#     if ($ldr7 =~ /[acdm]/) {
#         $formats{book} = 1;
#     } elsif ($ldr7 eq 'b') {
#         $formats{serial} = 1;
#     } elsif ($ldr7 eq 'i') {
#         if ( $t008data && substr($t008data,21,1) eq 'l' ) {
#       $formats{serial} = 1;
#       $formats{lleaf} = 1;
#         }
#     }
#     last CASE;
#       }
#       if ($ldr6 =~ /[bp]/) {
#     $formats{mss} = 1;
#     last CASE;
#       }
#       if ($ldr6 =~ /[cd]/) {
#     $formats{score} = 1;
#     last CASE;
#       }
#       if ($ldr6 =~ /[ef]/) {
#     $formats{map} = 1;
#     last CASE;
#       }
#       if ($ldr6 eq 'g') {
#     if ( $t008data && substr($t008data,33,1) =~ /[mv]/ ) {
#         $formats{video} = 1;
#     }
#     last CASE;
#       }
#       if ($ldr6 eq 'i') {
#     $formats{sound} = 1;
#     last CASE;
#       }
#       if ($ldr6 eq 'j') {
#     $formats{music} = 1;
#     last CASE;
#       }
#       if ($ldr6 eq 'k') {
#     if ( $t008data && substr($t008data,33,1) =~ /[ciklnoz]/ ) {
#         $formats{image} = 1;
#     }
#     if ( $t008data && substr($t008data,33,1) eq 'a' ) {
#         $formats{art} = 1;
#     }
#     last CASE;
#       }
#       if ($ldr6 eq 'm') {
#     if ( $t008data ) {
#         my $value = substr($t008data,26,1);
#         if ( $value =~ /[b]/ ) {
#       $formats{prog} = 1;
#         } else {
#       $formats{data} = 1;
#         }
#     }
#     last CASE;
#       }
#       if ($ldr6 eq 'o') {
#     $formats{other} = 1;
#     last CASE;
#       }
#       if ($ldr6 eq 'r') {
#     if ( $t008data && substr($t008data,33,1) eq 'a' ) {
#         $formats{art} = 1;
#     } else {
#         $formats{other} = 1;
#     }
#     last CASE;
#       }
#       if ($ldr6 =~ /[t]/) {
#     if ($ldr7 =~ /[am]/) {
#         $formats{book} = 1;
#     } elsif ($ldr7 =~ /[cd]/) {
#         $formats{mss} = 1;
#     }
#     last CASE;
#       }
# 
#       last CASE;
# 
#   }
# 
#     # What passes through the above filter without a format assignment:
#     #  * 'ai' unless type = 'l' (loose-leafs)
#     #  * 'as' (all language materials serials)
#     #  * 'g' unless type = 'm' or 'v' (films or videos)
#     #  * 'k' unless type is one of these: c i k l n o z (images) or type = a (original art)
#     #  * 'tb', 'ti', 'ts'
# 
#     ## check for serials if no format has been set up to now
#     if (! formatSet(\%formats)) {
#   if ($ldr7 eq 's') {
#       if ($t008data) {
#     my $type = substr($t008data,21,1);
#         TYPE: {
#       if ($type eq ' ') {
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       if ($type eq 'd') {
#           last TYPE;
#       }
#       if ($type eq 'l') {
#           last TYPE;
#       }
#       if ($type eq 'm') {
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       if ($type eq 'n') {
#           $formats{news} = 1;
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       if ($type eq 'p') {
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       if ($type eq 'w') {
#           last TYPE;
#       }
#       if ($type eq '|') {
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       last TYPE;
#         }
#       }
#   }
#     }
# 
#     ## check for serial from 006 if no format has been set up to now
#     if (! formatSet(\%formats)) {
#   if (my @t006 = $rec->field('006')) {
#       foreach (@t006) {
#     my $t006data = $_->data();
#     if ($t006data =~ /^s/) {
#         my $type = substr($t006data,4,1);
#       TYPE: {
#       if ($type eq ' ') {
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       if ($type eq 'd') {
#           last TYPE;
#       }
#       if ($type eq 'l') {
#           last TYPE;
#       }
#       if ($type eq 'm') {
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       if ($type eq 'n') {
#           $formats{news} = 1;
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       if ($type eq 'p') {
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       if ($type eq 'w') {
#           last TYPE;
#       }
#       if ($type eq '|') {
#           $formats{serial} = 1;
#           last TYPE;
#       }
#       last TYPE;
#       }
#         last;
#     }
#       }
#   }
#     }
# 
#     ## set online / microformats
#     if (my @t007 = $rec->field('007')) {
#       foreach (@t007) {
#         my $t007data = $_->data();
#         if ($t007data =~ /^cr/) {
#           $formats{online} = 1;
#           $formats{data} = 0;
#           last;
#         }
#         if ($t007data =~ /^h/) {
#           $formats{micro} = 1;
#           last;
#         }
#       }
#     }
# 
#     ## government documents
#     #  formats with gov doc codes
#     if ($ldr6 =~ /[aefgkmort]/) {
#   # if there is 008 data
#   if ($t008data) {
#       my $gdcode = '-';
#       my $cpcode = '---';
#       $gdcode = substr($t008data,28,1) if (length $t008data > 28);
#       $cpcode = substr($t008data,15,3) if (length $t008data > 17);
#       # federal document published in US
#       if ( ($gdcode eq 'f') && ($cpcode =~ /..u/) ) {
#     $formats{usdoc} = 1;
#       # local or state document published in New York
#       } elsif ( ($gdcode =~ /[clmos]/) & ($cpcode eq 'nyu') ) {
#     $formats{nydoc} = 1 if (isNYgovdoc($rec));
#       }
#   }
#     }
# 
#     ## conference proceedings
#     if (my @t6xx = $rec->field('6..')) {
#   TAG: foreach (@t6xx) {
#       my @s = $_->subfields();
#       for my $s (@s) {
#     if ($s->[0] =~ /[xv]/) {
#         if ( lc($s->[1]) =~ /congresses/ ) {
#       $formats{conf} = 1;
#       last TAG;
#         }
#     }
#       }
#   }
#     }
# 
#     ## thesis
#     if ($rec->field('502')) {
#   $formats{thesis} = 1;
#     }
# 
#     ## microforms / manuscripts
#     if (my $t245 = $rec->field('245')) {
#   if (my $subh = $t245->subfield('h')) {
#       if ($subh =~ /microform/i) {
#     $formats{micro} = 1;
#       } elsif ($subh =~ /manuscript/i) {
#     $formats{mss} = 1;
#       }
#   }
#     }
# 
#     ## default if no formats by now
#     if (! formatSet(\%formats)) {
#   $formats{other} = 1;
#     }
# 
#     my @formats = ();
#     foreach (@format_order) {
#   if ($formats{$_} == 1) {
#       push(@formats,$format_labels{$_});
#   }
#     }
# 
#     return \@formats;
# 
# }
# 
# sub formatSet {
# 
#     my $formats = shift;
# 
#     foreach (values %$formats) {
#   if ($_ == 1) {return 1};
#     }
# 
#     return 0;
# 
# }
# 
# sub isNYgovdoc {
# 
#     my $rec = shift;
# 
#     # extract publisher information
#     my @pub = ();
#     if (my $field = $rec->field('260')) {
#   if (my @sub = $field->subfield('b')) {
#       foreach my $sub (@sub) {
#     my $pub = lc($sub);
#     $pub =~ s/[^a-z ]/ /g;
#     $pub =~ s/\s{2,}/ /g;
#     $pub =~ s/^\s+//;
#     $pub =~ s/\s+$//;
#     push(@pub,$pub);
#       }
#   }
#     } elsif (my @fields = $rec->field('264')) {
#   foreach (@fields) {
#       if (my @sub = $_->subfield('b')) {
#     foreach my $sub (@sub) {
#         my $pub = lc($sub);
#         $pub =~ s/[^a-z ]/ /g;
#         $pub =~ s/\s{2,}/ /g;
#         $pub =~ s/^\s+//;
#         $pub =~ s/\s+$//;
#         push(@pub,$pub);
#     }
#       }
#   }
#     }
#     # no publisher is gov doc
#     return 1 unless (@pub);
# 
#     foreach my $pub (@pub) {
# 
#   if ($pub =~ /press/) {return 0};
#   if ($pub =~ /university/) {return 0};
#   if ($pub =~ /library/) {return 0};
#   if ($pub =~ /museum/) {return 0};
#   if ($pub =~ /school/) {return 0};
#   if ($pub =~ /conference/) {return 0};
#   if ($pub =~ /hospital/) {return 0};
#   if ($pub =~ /united nations/) {return 0};
#   if ($pub =~ /cornell/) {return 0};
#   if ($pub =~ /^american/) {return 0};
#   if ($pub =~ /^new york agricultural experiment station/) {return 0};
#   if ($pub =~ /text studies/) {return 0};
#   if ($pub =~ /^excelsior edition/) {return 0};
#   if ($pub =~ /^center for medieval and early renaissance studies/) {return 0};
#   if ($pub =~ /^wiley/) {return 0};
#   if ($pub =~ /^springer/) {return 0};
#   if ($pub =~ /^praeger/) {return 0};
#   if ($pub =~ /^penguin/) {return 0};
#   if ($pub =~ /^elsevier/) {return 0};
#   if ($pub =~ /^bantam book/) {return 0};
# 
#     }
# 
#     return 1;
# 
# }
# 
