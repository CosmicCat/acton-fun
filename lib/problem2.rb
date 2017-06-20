#!/usr/bin/env ruby

require "logger"
require "thor"

## Redact certain strings from gzipped logfiles
module Problem2

  ## Process a single line of input and generate a redaction if necessary
  class Redactor

    # modify this if you want to redact more fields
    def fields_to_redact
      ['SSN', 'CC']
    end

    # entry point - give it a line of log input to be processed
    # returns RedactionResult
    def redact(log_line)
      r = RedactionResult.new
      if should_redact?(log_line)
        r.redaction_performed = true
        r.new_log_line = UpdateCreateTokenizer.new(log_line).redact(fields_to_redact)
      else
        r.new_log_line = log_line
      end
      r
    end

    # given a log line, determines whether redaction is necessary
    def should_redact?(log_line)
      # cast matchdata objects to actual true and false for ease of testing
      (is_create_or_update?(log_line) && contains_dirty_fields?(log_line)) ? true : false
    end

    # we only care about create or update records
    def is_create_or_update?(log_line)
      # ignore case in the matches - example had a bunch of differing case
      log_line.match(/Account: \d+ Updated Record/i) || log_line.match(/Account: \d+ Added Record/i)
    end

    # does this line contain fields we must redact?
    def contains_dirty_fields?(log_line)
      fields_with_equals = fields_to_redact.map {|f| "#{f}="}
      regex = "(#{fields_with_equals.join("|")})"
      log_line.match(/#{regex}/)
    end

  end

  ## Passed back from Redactor::redact
  ## used to be more complicated
  ## to_s contains the log line for the new, redacted file
  class RedactionResult
    attr_reader :messages
    attr_accessor :redaction_performed, :new_log_line

    def initialize
      @redaction_performed = false
      @messages = []
      @new_log_line = ''
    end

    # not fully functional - but allows passing warnings from the tokenizer upwards
    def message(m)
      @messages << m
    end

    def to_s
      @new_log_line
    end
  end

  ## given a path, it
  #  * finds gzipped files with a glob
  #  * processes them line by line to redact sensitive information
  ## requirements
  # * original files are kept in place
  # * creates a ./redactions directory which contain the redacted logs
  # * creates an audit log for this procedure
  class FileHandler
    attr_reader :dir

    # entry point
    # redact each file found in the glob
    def redact_files
      setup_output
      Dir.glob(@dir.to_s + '/*.gz').each do |p|
        redact_file(p)
      end
    end

    # dir - the location of the log files we wish to process
    def initialize(dir)
      @dir = dir
    end

    # static filenames
    def temp_in
      File.join(temp_path, "in.tmp")
    end

    def temp_out
      File.join(temp_path, "out.tmp")
    end

    def output_path
      File.join(@dir, "redactions")
    end

    def temp_path
      File.join(output_path, "temp")
    end

    def output_log
      @output_log ||= Logger.new (logfile_path)
    end

    def logfile_path
      File.join(output_path, "redaction.log")
    end

    # full process for processing a single file
    # uses tempfiles for unzipped information
    def redact_file(path)
      filename = File.basename path
      unpack_infile_into_temp_dir(path)
      perform_redactions_on_file(filename)
      pack_redaction_into_redaction_dir(filename)
    end

    # given a file, process it for redactions
    def perform_redactions_on_file(filename)
      File.open(temp_out, 'w') do |outfile|
        lines_processed = 0
        lines_redacted = 0
        File.readlines(temp_in).each do |line|
          result = Problem2::Redactor.new.redact(line)
          outfile.write(result.to_s)
          lines_processed += 1
          lines_redacted += 1 if result.redaction_performed
        end
        output_log.info("Processed #{filename} - redacted #{lines_redacted}/#{lines_processed} of total lines processed")
      end
    end

    # recommend full testing before running this on logs that have already been redacted
    def setup_output
      raise "Please blow away output from previous run of this tool at: #{output_path}" if Dir.exist?(output_path)
      shell_command("mkdir #{output_path}")
      shell_command("mkdir #{temp_path}")
    end

    def unpack_infile_into_temp_dir(path)
      shell_command("zcat < #{path} > #{temp_in}")
    end

    def pack_redaction_into_redaction_dir(filename)
      shell_command("gzip < #{temp_out} > #{File.join(output_path, filename)}")
    end

    def shell_command(cmd)
      raise "Error executing #{cmd}" unless system(cmd)
    end

  end

  # allow redactions of single fields in a log line
  class UpdateCreateTokenizer
    attr_accessor :log_line, :fields

    def initialize(log_line)
      @log_line = log_line
      init_fields
    end

    def to_s
      @log_line
    end

    # find modifiable fieldnames
    def init_fields
      # remove the first part of the string
      fields_snippet = log_line.gsub(/^.* Fields: /, '')
      # split on fields
      field_strings = fields_snippet.split(/(?<=\"), /)
      # grab the fieldnames
      @fields = field_strings.map{|f| f.gsub(/=.*/,'')}
    end

    def rewrite_field(fieldname, new_value)
      # XXX - ERROR CHECKING HERE
      @log_line = @log_line.gsub(/#{fieldname}=\".*?\"/, "#{fieldname}=\"#{new_value}\"")
    end

    # given list of fields to redact, will rewrite then with redacted information
    def redact(fields_to_redact)
      fields_to_redact.each do |fieldname|
        rewrite_field(fieldname, 'XXX-REDACTED-XXX')
      end
      log_line
    end

  end

  # command line processing using thor gem
  class RedactionCli < Thor
    desc "redaction -p INPUT_PATH", "Redact CC and SSN from all audit logs in given directory"
    option :path, :required => true, :aliases => :p, :desc => 'path to directory of gzipped logfiles'
    def redact()
      p = Problem2::FileHandler.new(options[:path])
      p.redact_files
    end
  end

end

Problem2::RedactionCli.start(ARGV) unless ENV['INSIDE_TEST']
