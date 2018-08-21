class AcDocument
  attr_accessor :id, 
                :title, :abstract, :date, 
                :authors, :departments, :subjects, :types, :languages,
                :persistent_url


  # => {"id"=>"10.7916/D88G8TMC", "legacy_id"=>"ac:133608", "title"=>"Empirical Evaluation of Approaches to Testing Applications without Test Oracles", "author"=>["Murphy, Christian", "Kaiser, Gail E."], "abstract"=>"Software testing of applications in fields like scientific computing, simulation, machine learning, etc. is particularly challenging because many applications in these domains have no reliable \"test oracle\" to indicate whether the program's output is correct when given arbitrary input. A common approach to testing such applications has been to use a \"pseudo-oracle\", in which multiple independently-developed implementations of an algorithm process an input and the results are compared. Other approaches include the use of program invariants, formal specification languages, trace and log file analysis, and metamorphic testing. In this paper, we present the results of two empirical studies in which we compare the effectiveness of some of these approaches, including metamorphic testing, pseudo-oracles, and runtime assertion checking. We also analyze the results in terms of the software development process, and discuss suggestions for practitioners and researchers who need to test software without a test oracle.", "date"=>"2010", "department"=>["Computer Science"], "subject"=>["Computer science"], "type"=>["Reports"], "language"=>["English"], "persistent_url"=>"https://doi.org/10.7916/D88G8TMC", "created_at"=>"2011-06-09T16:01:18Z", "modified_at"=>"2018-02-16T23:30:20Z"}

  def initialize(document = nil)
    return unless document.present?

    # identifiers
    @id             = document['id']
    @persistent_url = document['persistent_url']

    # strings
    @title     = document['title']
    @abstract  = document['abstract']
    @date      = document['date']

    # arrays
    @authors = document['author']
    @departments = document['department']
    @subjects = document['subject']
    @types = document['type']
    @languages = document['language']

  end

end

