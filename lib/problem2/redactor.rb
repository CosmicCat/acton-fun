module Problem2

  class Redactor
    def fields_to_redact
      ['SSN', 'CC']
    end

    def redact(log_line)
      if should_redact?(log_line)
        return perform_redaction(log_line)
      end
      return log_line
    end

    def perform_redaction(log_line)

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
      puts regex
      log_line.match(/#{regex}/)
    end

  end

end
