module Sass
  module Plugin
    class ImporterCache < Hash
      alias_method :_get, :[]

      def initialize
        super() {|h, importer| h.store(importer, {})}
      end

      def [](importer, uri)
        super(importer)[uri]
      end

      def []=(importer, uri, c)
        _get(importer)[uri] = c
      end

      def delete(importer, uri)
        _get(importer).delete(uri)
      end
    end
  end
end