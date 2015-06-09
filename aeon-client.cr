require "socket"

class AeonClient

  def self.main
    alter_aeon_server = "alteraeon.com"
    alter_aeon_port = 3000
    connection = TCPSocket.new(alter_aeon_server, alter_aeon_port)
    spawn autoreader(connection)
    Signal::INT.trap do
      connection << "quit" if connection
      sleep 1
      connection.close rescue nil
      puts "Exiting.."
      exit 0
    end
    loop do
      begin
        buff = gets
        connection << buff.to_s if connection
        break if connection.closed?
      rescue e : Exception
        puts e
      end
    end
  end

  def self.autoreader(connection)
    loop do
      begin
        break if connection.closed?
        buf :: UInt8[4096]
        len = connection.read(buf.to_slice)
        if len > 0
          data = String.new(buf.buffer, len)
          print data if !data.empty?
        else
          sleep 0.5
        end
      rescue e : Exception
        puts e
      end
    end
  end
end

AeonClient.main