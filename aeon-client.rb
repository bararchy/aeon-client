require 'socket'


class AeonClient

  def self.main
    alter_aeon_server = "alteraeon.com"
    alter_aeon_port = 3000
    connection = TCPSocket.new(alter_aeon_server, alter_aeon_port)
    Thread.new do
      autoreader(connection)
    end
    loop do
      begin
        buff = gets.chomp
        connection.write("#{buff}\n")
        break if connection.closed?
      rescue Exception => e
        puts e
      end
    end
  end

  def self.autoreader(connection)
    loop do
      begin
        data = connection.readpartial(512)
        print data unless data.to_s.empty?
        break if connection.closed?
      rescue IO::WaitReadable
        IO.select([io])
        retry
      rescue EOFError
        sleep 1
        retry
      rescue Exception => e
        sleep 0.5
        puts e
        retry
      end
    end
  end
end

AeonClient.main