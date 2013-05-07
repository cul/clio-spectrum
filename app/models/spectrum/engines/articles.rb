module Spectrum
  module Engines
    class Articles < BaseEngine

      def initialize(params = {})

        summon = SerialSolutions::SummonAPI.new('category' => 'articles', 'new_search' => true, 's.q' => params['q'], 's.ps' => 10)

        @result = summon.search
        @docs = summon.search
        @count = summon.search.record.count.to_i
        @url = articles_search_path(summon.search.query.to_hash)
      end
    end
  end
end

