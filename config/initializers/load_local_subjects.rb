
# NEXT-1601 - mapping table from LOC subject heading to preferred local NNC subject heading
LOCAL_SUBJECTS = {}

# The app_config.yml toggle value controls whether the local-subjects database table 
# is loaded into into a mapping table to be used in display and bib indexing.
# The Authorities Load will populate the mapping table regardless.
if APP_CONFIG['enable_local_subjects'] 
  if ActiveRecord::Base.connection.table_exists?('local_subjects')
    LocalSubject.find_each do |local_subject|
      LOCAL_SUBJECTS[ local_subject.loc_subject ] = local_subject.nnc_subject
    end
  end
end


