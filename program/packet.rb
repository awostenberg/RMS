module PacketParser
  def self.parse(data)
    id = data[0]
    data = data[1..-1]
    case id
      # When someone wants to connect
      when 0x0
        # Remove the 2nd character (specifies protocol version)
        data = data[1..-1]
        # Strings are padded with spaces
        data = data.split(" ")[0..1]
    end
    # It should now be an Array
    data
  end
end