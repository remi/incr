module Incr
  module Command
    class Mix
      VERSION_REGEX = /@?version:?\W*\"(\d*.\d*.\d*)"/
      VERSION_REPLACEMENT_PATTERNS = [
        "version: \"%s\"",
        "@version \"%s\""
      ]

      def initialize(args, global_options)
        @segment = args[0]
        @mix_file_filename = File.join('.', global_options[:versionFileDirectory], 'mix.exs')
        @tag_pattern = global_options[:tagNamePattern]
        @commit = global_options[:commit]
        @tag = global_options[:tag]
      end

      def execute
        file_content = parse_content(@mix_file_filename)
        if file_content == nil
          return
        end

        file_version = file_content.match(VERSION_REGEX)[1]
        old_version = SemVersion.new(file_version)
        new_version = Incr::Service::Version.increment_segment(old_version, @segment)
        replace_file_version(old_version, new_version)

        new_tag = @tag_pattern % new_version.to_s

        puts new_tag

        repository = Incr::Service::Repository.new('.')
        repository.add(@mix_file_filename)
        repository.commit(new_tag) if @commit
        repository.tag(new_tag) if @tag
      end

      private

      def parse_content(filename)
        if !File.exist?(filename)
          STDERR.puts("[Err] '#{filename}' not found.")
          return nil
        end

        IO.read(filename)
      end

      def replace_file_version(old_version, new_version)
        VERSION_REPLACEMENT_PATTERNS.each do |pattern|
          old_version_pattern = format(pattern, old_version.to_s)
          new_version_pattern = format(pattern, new_version.to_s)

          Incr::Service::FileHelper.replace_string_once(@mix_file_filename, old_version_pattern, new_version_pattern)
        end
      end
    end
  end
end
