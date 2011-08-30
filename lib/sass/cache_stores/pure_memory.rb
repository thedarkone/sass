module Sass
  module CacheStores
    class PureMemory < Memory
      def retrieve(key, sha)
        if (bucket = @contents[key]) && bucket[:sha] == sha
          bucket[:obj]
        end
      end
    end
  end
end
