
# global mapping table from LOC subject heading to preferred local NNC subject heading
LOCAL_SUBJECTS = {}

if ActiveRecord::Base.connection.table_exists?('local_subjects')
  LocalSubject.find_each do |local_subject|
    LOCAL_SUBJECTS[ local_subject.loc_subject ] = local_subject.nnc_subject
  end
end

# local_subject_file = APP_CONFIG['extract_home'] + '/local_subjects/local_subjects.yml'
# LOCAL_SUBJECTS = File.exist?(local_subject_file) ? YAML.load(File.read(local_subject_file)) : {}


