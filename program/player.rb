class Player
  attr_reader(:name, :ip)

  def initialize(name, ip)
    @name, @ip = name, ip
  end
end