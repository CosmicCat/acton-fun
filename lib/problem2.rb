require "pathname"
require "logger"

module Problem2

  class Redactor
    def fields_to_redact
      ['SSN', 'CC']
    end

    def redact(log_line)
      r = RedactionResult.new
      r.redacted = log_line
      if should_redact?(log_line)
        r.redacted_plus_plus()
        r.redacted = UpdateCreateTokenizer.new(log_line).redact(fields_to_redact)
      end
      r
    end

    def perform_redaction(log_line)
      UpdateCreateTokenizer.new(log_line).redact
    end

    def should_redact?(log_line)
      # cast matchdata objects to actual true and false for ease of testing
      (is_create_or_update?(log_line) && contains_dirty_fields?(log_line)) ? true : false
    end

    def is_create_or_update?(log_line)
      # ignore case in the matches
      log_line.match(/Account: \d+ Updated Record/i) || log_line.match(/Account: \d+ Added Record/i)
    end

    def contains_dirty_fields?(log_line)
      fields_with_equals = fields_to_redact.map {|f| "#{f}="}
      regex = "(#{fields_with_equals.join("|")})"
      log_line.match(/#{regex}/)
    end

  end

  class RedactionResult
    attr_reader :lines_processed, :lines_redacted, :messages, :redacted_contents
    attr_accessor :redacted

    def initialize
      @lines_processed = 0
      @lines_redacted = 0
      @messages = []
      @redacted = ''
    end

    def processed_plus_plus
      @lines_processed += 1
    end

    def redacted_plus_plus
      @lines_redacted += 1
    end

    def message(m)
      @messages << m
    end

    def to_s
      @redacted
    end
  end

  class FileHandler
    attr_reader :dir

    def initialize(dir)
      @dir = dir
    end

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

    def redact_files
      setup_output
      Dir.glob(@dir.to_s + '/*.gz').each do |p|
        redact_file(p)
      end
    end

    def redact_file(path)
      filename = File.basename path
      unpack_infile_into_temp_dir(path)
      perform_redactions_on_file(filename)
      pack_redaction_into_redaction_dir(filename)
    end

    def perform_redactions_on_file(filename)
      File.open(temp_out, 'w') do |outfile|
        lines_processed = 0
        lines_redacted = 0
        File.readlines(temp_in).each do |line|
          result = Problem2::Redactor.new.redact(line)
          outfile.write(result.to_s)
          lines_processed += 1
          lines_redacted += result.lines_redacted
        end
        output_log.info("Processed #{filename} - redacted #{lines_redacted}/#{lines_processed} of total lines processed")
      end
    end

    def setup_output
      raise "Please blow away output from previous run of this tool at: #{output_path}" if Dir.exist?(output_path)
      shell_command("mkdir #{output_path}")
      shell_command("mkdir #{temp_path}")
    end

    def unpack_infile_into_temp_dir(path)
      shell_command("gzcat #{path} > #{temp_in}")
    end

    def pack_redaction_into_redaction_dir(filename)
      shell_command("gzip < #{temp_out} > #{File.join(output_path, filename)}")
    end

    def shell_command(cmd)
      raise "Error executing #{cmd}" unless system(cmd)
    end

    def shell_command_with_output(cmd)
      out = `cmd`
      raise "Error executing #{cmd}" unless $?.success
      out
    end

  end

  class UpdateCreateTokenizer
    attr_accessor :log_line, :fields

    def initialize(log_line)
      @log_line = log_line
      init_fields
    end

    def to_s
      @log_line
    end
    
    def init_fields
      fields_snippet = log_line.gsub(/^.* Fields: /, '')
      field_strings = fields_snippet.split(/(?<=\"), /)
      @fields = field_strings.map{|f| f.gsub(/=.*/,'')}
    end

    def rewrite_field(fieldname, new_value)
      # BUG - ERROR CHECKING HERE
      @log_line = @log_line.gsub(/#{fieldname}=\".*?\"/, "#{fieldname}=\"#{new_value}\"")
    end

    def redact(fields_to_redact)
      fields_to_redact.each do |fieldname|
        rewrite_field(fieldname, 'XXX-REDACTED-XXX')
      end
      log_line
    end
    
  end

end
