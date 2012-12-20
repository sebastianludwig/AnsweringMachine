module ViewHelper
  def escape_javascript(html_content)
    return '' unless html_content
    javascript_mapping = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n' }
    javascript_mapping.merge("\r" => '\n', '"' => '\\"', "'" => "\\'")
    escaped_string = html_content.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { javascript_mapping[$1] }
    "\"#{escaped_string}\""
  end
  
  def css_class_for_http_status(status)
    return 'label-success' if (200...300) === status
    return 'label-warning' if (300...400) === status
    return 'label-important' if (400...500) === status
    return 'label-inverse' if (500...600) === status
    return ''
  end
  
  def repeat_description(count)
    case count
      when 0 then "no"
      when -1 then "infinitely"
      when 1 then "1 time"
      else "#{count} times"
    end
  end
  
  def http_status_name(code)
    case code
      when 200 then "OK"
      when 201 then "Created"
      when 202 then "Accepted"
      when 203 then "Non-Authoritative Information"
      when 204 then "No Content"
      when 205 then "Reset Content"
      when 206 then "Partial Content"

      when 300 then "Multiple Choices"
      when 301 then "Moved Permanently"
      when 302 then "Found"
      when 303 then "See Other"
      when 304 then "Not Modified"
      when 306 then "Switch Proxy"
      when 307 then "Temporary Redirect"
      when 308 then "Resume Incomplete"

      when 400 then "Bad Request"
      when 401 then "Unauthorized"
      when 402 then "Payment Required"
      when 403 then "Forbidden"
      when 404 then "Not Found"
      when 405 then "Method Not Allowed"
      when 406 then "Not Acceptable"
      when 407 then "Proxy Authentication Required"
      when 408 then "Request Timeout"
      when 409 then "Conflict"
      when 410 then "Gone"
      when 411 then "Length Required"
      when 412 then "Precondition Failed"
      when 413 then "Request Entity Too Large"
      when 414 then "Request-URI Too Long"
      when 415 then "Unsupported Media Type"
      when 416 then "Requested Range Not Satisfiable"
      when 417 then "Expectation Failed"
      when 418 then "I'm a teapot"

      when 500 then "Internal Server Error"
      when 501 then "Not Implemented"
      when 502 then "Bad Gateway"
      when 503 then "Service Unavailable"
      when 504 then "Gateway Timeout"
      when 505 then "HTTP Version Not Supported"
      else "Unknown"
    end
  end
end