$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'program/server'
serv = Server.new
serv.start

exit
loop do
  sleep(30)
  url = send_heartbeat
end