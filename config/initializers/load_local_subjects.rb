
# global mapping table from LOC subject heading to preferred local NNC subject heading
LOCAL_SUBJECTS = {}

if ActiveRecord::Base.connection.table_exists?('local_subjects')
  LocalSubject.find_each do |local_subject|
    LOCAL_SUBJECTS[ local_subject.loc_subject ] = local_subject.nnc_subject
  end
end




