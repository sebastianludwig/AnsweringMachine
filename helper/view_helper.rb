module ViewHelper
  def css_class_for_http_status(status)
    return 'label-success' if (200...300) === status
    return 'label-important' if (400...500) === status
    return 'label-inverse' if (500...600) === status
    return ''
  end
  
  def truncate(text, length = 30, truncate_string = "...")
      if text
        l = length - truncate_string.length
        (text.length > length ? text[0...l] + truncate_string :  text).to_s
      end
    end
end