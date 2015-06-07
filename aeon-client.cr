require "socket"

class AeonClient

  def self.main
    alter_aeon_server = "alteraeon.com"
    alter_aeon_port = 3000
    connection = TCPSocket.new(alter_aeon_server, alter_aeon_port)
    spawn autoreader(connection)
    spawn writer(connection)
    Signal::INT.trap do
      connection << "quit" if connection
      sleep 1
      connection.close rescue nil
      puts "Exiting.."
      exit 0
    end
    while connection
      sleep 1
    end

  end

  def self.writer(connection)
    while connection
      begin
        buff = gets
        connection << buff.to_s if connection
      rescue e : Exception
        sleep 0.5
      end
    end
  end

  def self.autoreader(connection)
    loop do
      begin
        while(buff = connection.read_nonblock(4096))
          print buff if buff
        end
      rescue e : Exception
        sleep 0.5
      end
    end
  end

end

AeonClient.main