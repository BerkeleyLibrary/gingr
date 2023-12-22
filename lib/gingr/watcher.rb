# frozen_string_literal: true
require 'listen'
require 'open3'
require 'thor'
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

    def initialize(root_dir = nil, options = {})
      # This is the Gingr root directory, not the directory to be watched.
      # Watcher watches the ./ready directory under this one.
      @root_dir = root_dir || ENV['GINGR_WATCH_DIRECTORY'] || '/opt/app/data/gingr'

      # Options are passed as-is to `gingr all`, so they should match the
      # arguments you'd otherwise pass to that command
      @options = options

      validate_directories!
    end

    # We receive parsed options from Thor but then have to pass them back to the CLI
    # un-parsed, so we essentially reverse option-parsing here. Returns an Array so
    # it's easier to pass to Open3.capture3.
    def arguments
      options.to_h { |k, v| [dasherize(k.to_s), v.to_s] }.to_a.flatten
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
            begin
              exec_gingr_all!(zipfile)
            rescue => e
              logger.debug("Continuing to watch despite error: #{e}")
            end
          end
        end
      end
    end

    def exec_gingr_all!(zipfile)
      command = ['gingr', 'all', zipfile, *arguments]

      logger.info("Processing zipfile: #{zipfile}")
      logger.debug("Running command: #{command}")
      logs, status = Open3.capture2e(*command)

      if !status.success?
        logger.error("Error processing #{zipfile}, moving to #{processed_dir}")
        logger.debug("Execute logs: #{logs}")

        write_logs(logs, zipfile, failed_dir)
        FileUtils.mv(zipfile, failed_dir)

        raise SubprocessError, "Call to `gingr all` failed: #{status}"
      else
        logger.info("Processed #{zipfile}, moving to #{processed_dir}")
        logger.debug("Execute logs: #{logs}")

        write_logs(logs, zipfile, processed_dir)
        FileUtils.mv(zipfile, processed_dir)
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

    def dasherize(str)
      (str.length > 1 ? "--" : "-") + str.tr("_", "-")
    end

    def write_logs(logs, zipfile, logdir)
      logfile = File.join(logdir, "#{File.basename(zipfile, '.*')}.log")
      File.write(logfile, logs)
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
