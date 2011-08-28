require 'pathname'

module Sass
  module Importers
    # The default importer, used for any strings found in the load path.
    # Simply loads Sass files from the filesystem using the default logic.
    class Filesystem < Base

      attr_accessor :root

      # Creates a new filesystem importer that imports files relative to a given path.
      #
      # @param root [String] The root path.
      #   This importer will import files relative to this path.
      def initialize(root)
        @root = File.expand_path(root)
      end

      # @see Base#find_relative
      def find_relative(name, base, options)
        _find(File.dirname(base), name, options)
      end

      # @see Base#find
      def find(name, options)
        _find(@root, name, options)
      end

      # @see Base#mtime
      def mtime(name, options)
        try_mtime(name) || try_mtime(File.join(@root, name))
      end

      # @see Base#key
      def key(name, options)
        [self.class.name + ":" + File.dirname(File.expand_path(name)),
          File.basename(name)]
      end

      # @see Base#to_s
      def to_s
        @root
      end

      def hash
        @root.hash
      end

      def eql?(other)
        root.eql?(other.root)
      end

      protected

      # If a full uri is passed, this removes the root from it
      # otherwise returns the name unchanged
      def remove_root(name)
        if name.index(@root + "/") == 0
          name[(@root.length + 1)..-1]
        else
          name
        end
      end

      EXTENSIONS = {'sass' => :sass, 'scss' => :scss}

      # A hash from file extensions to the syntaxes for those extensions.
      # The syntaxes must be `:sass` or `:scss`.
      #
      # This can be overridden by subclasses that want normal filesystem importing
      # with unusual extensions.
      #
      # @return [{String => Symbol}]
      def extensions
        EXTENSIONS
      end

      def each_possible_file(name)
        name = escape_glob_characters(name)
        dirname, basename, extname = split(name)
        exts = extensions
        syntax = exts[extname]

        if syntax
          inverted = exts.invert
          yield "#{dirname}/#{basename}.#{inverted[syntax]}",  syntax
          yield "#{dirname}/_#{basename}.#{inverted[syntax]}", syntax
        else
          exts.sort.each do |ext, syn|
            yield "#{dirname}/#{basename}.#{ext}",  syn
            yield "#{dirname}/_#{basename}.#{ext}", syn
          end
        end
      end

      def escape_glob_characters(name)
        name.gsub(/[\*\[\]\{\}\?]/) do |char|
          "\\#{char}"
        end
      end

      REDUNDANT_DIRECTORY = %r{#{Regexp.escape(File::SEPARATOR)}\.#{Regexp.escape(File::SEPARATOR)}}
      # Given a base directory and an `@import`ed name,
      # finds an existant file that matches the name.
      #
      # @param dir [String] The directory relative to which to search.
      # @param name [String] The filename to search for.
      # @return [(String, Symbol)] A filename-syntax pair.
      def find_real_file(dir, name, cache = nil)
        if cache
          uri_cache = cache.uri
          path = File.expand_path(File.join(dir, name))
          if v = uri_cache[self, path]
            v
          elsif v == false
          else
            uri_cache[self, path] = _find_real_file(dir, name) || false
          end
        else
          _find_real_file(dir, name)
        end
      end

      def _find_real_file(dir, name)
        each_possible_file(remove_root(name)) do |f, s|
          path = (dir == ".") ? f : "#{dir}/#{f}"
          if File.file?(path)
            path.gsub!(REDUNDANT_DIRECTORY,File::SEPARATOR)
            return path, s
          end
        end
        nil
      end

      # Splits a filename into three parts, a directory part, a basename, and an extension
      # Only the known extensions returned from the extensions method will be recognized as such.
      def split(name)
        extension = nil
        dirname, basename = File.dirname(name), File.basename(name)
        if basename =~ /^(.*)\.(#{extensions.keys.map{|e| Regexp.escape(e)}.join('|')})$/
          basename = $1
          extension = $2
        end
        [dirname, basename, extension]
      end

      private

      def _find(dir, name, options)
        cache = options && options[:compile_cache]
        full_filename, syntax = find_real_file(dir, name, cache)
        return unless full_filename

        options[:syntax] = syntax
        options[:filename] = full_filename
        options[:importer] = self
        _make_engine(full_filename, options, cache)
      end

      def _make_engine(full_filename, options, cache = nil)
        if cache
          filename_to_sha = cache.filename_to_sha
          if sha = filename_to_sha[full_filename]
            Sass::Engine.for_sha(sha, full_filename, options)
          else
            Sass::Engine.for_file(full_filename, options).tap do |engine|
              filename_to_sha[full_filename] = engine.sha
            end
          end
        else
          Sass::Engine.for_file(full_filename, options)
        end
      end

      def join(base, path)
        Pathname.new(base).join(path).to_s
      end

      def try_mtime(path)
        File.mtime(path)
      rescue Errno::ENOENT
      end
    end
  end
end
