module Problem2

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
