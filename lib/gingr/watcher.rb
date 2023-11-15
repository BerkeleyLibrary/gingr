# frozen_string_literal: true
require 'listen'
require 'open3'
require_relative 'logging'

module Gingr
  class Watcher
    include Logging

    # Only watch for files in WATCHED_DIRECTORIES[:READY] that match this pattern
    WATCH_FILTER = Regexp.compile(/\.zip$/)

    WATCHED_DIRECTORIES = {
      # Directory into which new files are dropped when ready for processing.
      # .watch! monitors this for new .zip's.
      READY: 'ready'.freeze,
      # Directory into which successfully processed files are moved post-processing.
      PROCESSED: 'processed'.freeze,
      # Directory into which failed files are moved post-processing.
      FAILED: 'failed'.freeze,
    }

    attr_reader :options
    attr_reader :root_dir

    def initialize(root_dir, *options)
      # This is the Gingr root directory, not the directory to be watched.
      # Watcher watches the ./ready directory under this one.
      @root_dir = root_dir

      # Options are passed as-is to `gingr all`, so they should match the
      # arguments you'd otherwise pass to that command
      @options = options

      validate_directories!
    end

    def start!
      start
      sleep
    end

    def start
      logger.info("Monitoring directory for new zipfiles: #{ready_dir}")
      listener.start unless listener.processing?
    end

    def listener
      @listener ||= begin
        Listen.to(ready_dir, only: WATCH_FILTER, force_polling: true) do |_, added, _|
          added.each do |zipfile|
            logger.info("Processing zipfile: #{zipfile}")

            begin
              exec_gingr_all!(zipfile)
            rescue => e
              logger.error("Error processing #{zipfile}, moving to #{failed_dir}: #{e.inspect}")
            end
          end
        end
      end
    end

    def exec_gingr_all!(zipfile)
      begin
        command = ['gingr', 'all', zipfile, *options]
        logger.debug("Running command: #{command}")

        stdout, stderr, status = Open3.capture3(*command)
        if !status.success?
          raise SubprocessError, "Call to `gingr all` failed: #{status}"
        end

        logger.debug("Processed #{zipfile}, moving to #{processed_dir}")
        FileUtils.mv(zipfile, processed_dir)
      rescue => e
        FileUtils.mv(zipfile, failed_dir)
        File.write(error_log_for(zipfile), collate_logs(stdout, stderr))
        raise
      end
    end

    def ready_dir
      @ready_dir ||= File.join(@root_dir, WATCHED_DIRECTORIES[:READY])
    end

    def processed_dir
      @processed_dir ||= File.join(@root_dir, WATCHED_DIRECTORIES[:PROCESSED])
    end

    def failed_dir
      @failed_dir ||= File.join(@root_dir, WATCHED_DIRECTORIES[:FAILED])
    end

    private

    def collate_logs(stdout, stderr)
      "#{stdout}\n#{stderr}\n"
    end

    def error_log_for(zipfile)
      File.join(failed_dir, "#{File.basename(zipfile, '.*')}.log")
    end

    def validate_directories!
      WATCHED_DIRECTORIES.values
        .collect { |dirname| public_send("#{dirname}_dir") }
        .each &method(:validate_directory!)
    end

    def validate_directory!(directory)
      if !File.writable?(directory)
        raise DirectoryError, "Directory is not writable: #{directory}"
      end
    end

    # Typed errors to help with tests / figuring out what exactly failed
    class WatcherError < StandardError; end
    class DirectoryError < WatcherError; end
    class SubprocessError < WatcherError; end
  end
end
