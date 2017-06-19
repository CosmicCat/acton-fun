module Problem2

  class UpdateCreateTokenizer
    attr_accessor :log_line, :fields

    def initialize(log_line)
      @log_line = log_line
      init_fields
    end
    
    def init_fields
      fields_snippet = log_line.gsub(/^.* Fields: /, '')
      field_strings = fields_snippet.split(/(?<=\"), /)
      @fields = field_strings.map{|f| f.gsub(/=.*/,'')}
    end

    def rewrite_field(fieldname, new_value)
      # ERROR CHECKING
      @log_line = @log_line.gsub(/#{fieldname}=\".*?\"/, "#{fieldname}=\"#{new_value}\"")
    end
    
  end

end
