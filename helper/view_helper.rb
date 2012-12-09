module ViewHelper
  def css_class_for_http_status(status)
    return 'label-success' if (200...300) === status
    return 'label-warning' if (300...400) === status
    return 'label-important' if (400...500) === status
    return 'label-inverse' if (500...600) === status
    return ''
  end
  
  def http_status_codes(group)
    return [
      { :code => 200, :name => "OK" },
      { :code => 201, :name => "Created" },
      { :code => 202, :name => "Accepted" },
      { :code => 203, :name => "Non-Authoritative Information" },
      { :code => 204, :name => "No Content" },
      { :code => 205, :name => "Reset Content" },
      { :code => 206, :name => "Partial Content" }
    ] if group == :successful
    
    return [
      { :code => 300, :name => "Multiple Choices" },
      { :code => 301, :name => "Moved Permanently" },
      { :code => 302, :name => "Found" },
      { :code => 303, :name => "See Other" },
      { :code => 304, :name => "Not Modified" },
      { :code => 306, :name => "Switch Proxy" },
      { :code => 307, :name => "Temporary Redirect" },
      { :code => 308, :name => "Resume Incomplete" }
    ] if group == :redirection
    
    return [
      { :code => 400, :name => "Bad Request" },
      { :code => 401, :name => "Unauthorized" },
      { :code => 402, :name => "Payment Required" },
      { :code => 403, :name => "Forbidden" },
      { :code => 404, :name => "Not Found" },
      { :code => 405, :name => "Method Not Allowed" },
      { :code => 406, :name => "Not Acceptable" },
      { :code => 407, :name => "Proxy Authentication Required" },
      { :code => 408, :name => "Request Timeout" },
      { :code => 409, :name => "Conflict" },
      { :code => 410, :name => "Gone" },
      { :code => 411, :name => "Length Required" },
      { :code => 412, :name => "Precondition Failed" },
      { :code => 413, :name => "Request Entity Too Large" },
      { :code => 414, :name => "Request-URI Too Long" },
      { :code => 415, :name => "Unsupported Media Type" },
      { :code => 416, :name => "Requested Range Not Satisfiable" },
      { :code => 417, :name => "Expectation Failed" },
      { :code => 418, :name => "I'm a teapot" }
    ] if group == :client_error
    
    return [
      { :code => 500, :name => "Internal Server Error" },
      { :code => 501, :name => "Not Implemented" },
      { :code => 502, :name => "Bad Gateway" },
      { :code => 503, :name => "Service Unavailable" },
      { :code => 504, :name => "Gateway Timeout" },
      { :code => 505, :name => "HTTP Version Not Supported" },
      { :code => 511, :name => "Network Authentication Required" }
    ] if group == :server_error
    
    return []
  end
end