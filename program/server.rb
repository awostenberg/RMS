require 'socket'
require 'base62'
# For escaping URIs
require 'uri'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'player'

class Server
  Config_Template = "name = devtest (not a real server)
port = 25565
public = true
maxplayers = 0"
  Properties_Template = "heartbeat_interval = 30"

  def initialize
    @cfg = map_config("server.properties", Properties_Template)
    @salt = rand_base_62(16)
    @players = []
  end

# Create the file if it doesn't already exist, then return
# the contents
  def load_config(fname, template)
    unless File.exist?(fname)
      # Create the file
      File.open(fname, "wb") { |f| f.print(template.to_s) }
      # We don't actually read the file since we know what's in it
      return template
    end
    # Read the entire file
    File.open(fname, "rb") { |f| return f.readlines.join }
  end

# Maps the config file to a hashmap, e.g. this:
#  foo = hello
#  bar = world
# becomes:
#  {"foo"=>"hello", "bar"=>"world"}
  def map_config(*args)
    pairs = load_config(*args).split("\n")
    result = {}
    pairs.each { |raw|
      key, val = raw.split(" = ")
      result[key] = val
    }
    result
  end

  def rand_base_62(length)
    result = ""
    numset = ([0..9, "a".."z", "A".."Z"].collect { |char| char.to_a }).flatten
    length.times {
      result << numset.sample.to_s
    }
    result
  end

# Returns a string of URL parameters (loaded from server.config)
# with the argument extras added
  def param_str(extras=[])
    result = []
    needed_vals = ["name", "port", "public", "max"]
    props = map_config("server.properties", Config_Template)
    needed_vals.each {|v|
      result << "#{URI.escape(v)}=#{URI.escape(props[v])}"
    }
    result += extras
    result.join("&")
  end

  def send_heartbeat
    hb_host = "www.minecraft.net"
    port = 80
    # Parameters that can't be found in the config file
    params = param_str(["salt=#{@salt}", "version=7", "users=0"])
    hb_page = "/heartbeat.jsp?#{params}"
    @last_url = hb_host + hb_page
    # POST requests also worlk
    request = "GET #{hb_page} HTTP/1.0\r\n\r\n"
    # Open a connection
    hbsocket = TCPSocket.open(hb_host, port)
    # Register the server
    hbsocket.print(request)
    # Return minecraft.net's response (should be the url to this
    # server in plain text)
    hbsocket.read.split("\r\n\r\n", 2).last
  end

  def start_handle_connections
    # Start listening
    @listener = TCPServer.new(@cfg["port"].to_i)
    Thread.fork do
      loop do
        Thread.start(@listener.accept) do |client|
          data = PacketParser.parse(client.read)
          puts "#{data[0]} attempted connection from #{client.addr.last}"
        end
      end
    end
  end

  # Not threaded
  def start
    resp = send_heartbeat
    unless resp[0..6] == "http://"
      puts "Got unexpected response from http://minecraft.net/heartbeat.jsp!"
      puts "-- DEBUG --"
      puts "Expected URL but got this from #{@last_url}:"
      puts resp
      puts "-- END DEBUG --"
      exit 1
    end
    start_handle_connections
    puts "Server up! You can connect to this server in an internet browser via `#{resp}'."
    loop do
      sleep(@cfg["heartbeat_interval"].to_i)
      send_heartbeat
    end
  end
end