class LooseTightDictionary
  # Identities take effect when needle and haystack both match a regexp
  # Then the captured part of the regexp has to match exactly
  class Identity
    include ExtractRegexp
    
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = extract_regexp regexp_or_str
    end
    
    # Two strings are "identical" if they both match this identity and the captures are equal.
    #
    # Only returns true/false if both strings match the regexp.
    # Otherwise returns nil.
    def identical?(str1, str2)
      if str1_match_data = regexp.match(str1) and match_data = regexp.match(str2)
        str1_match_data.captures == match_data.captures
      else
        nil
      end
    end
  end
end
