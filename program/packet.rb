module PacketParser
  def self.parse(data)
    # The first character of a packet is always the ID
    id = data.unpack("U")[0]
    data[0] = ""
    case id
      # When someone wants to connect
      when 0x00
        puts "Got to when condition"
        # Remove the 2nd character (specifies protocol version)
        data[0] = ""
        # Strings are padded with spaces
        #result = data.split("  ")[0..1]
      else
        puts "Unknown packet recieved! ID: #{id}"
        return false
    end
    result = extract_strings(data)
    # It should now be an Array
    result
  end

  # Returns an Array containing all minecraft classic formatted strings
  # from +data,+
  def self.extract_strings(data)
    #result = []
    # Non-space character followed by two spaces
    #start_match = /\S\s{2}/
    data.split(/\S\s{2}/)
    #str_start, str_end = data =~ start_match + 2, data =~ end_match
  end
end