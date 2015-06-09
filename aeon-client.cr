require "socket"
require "colorize"
require "toml"

class AeonClient

  def self.main
    config_hash = get_configs
    connection = TCPSocket.new(config_hash[:server].to_s, config_hash[:port].to_i)
    login(connection, config_hash)
    spawn autoreader(connection)
    #spawn keep_alive(connection)
    Signal::INT.trap do
      handle_quit(connection)
    end
    loop do
      begin
        break if connection.closed?
        data = gets
        handle = special_write_handles(data, connection)
        connection << data.to_s if connection && handle == false
      rescue e : Exception
        puts e
      end
    end
    handle_quit(connection) unless connection.closed?
  end

  def self.autoreader(connection)
    loop do
      begin
        break if connection.closed?
        buf :: UInt8[1024]
        len = connection.read(buf.to_slice)
        if len > 0
          #STDOUT.write(buf.to_slice, len); STDOUT.flush
          data = String.new(buf.buffer, len)
          special_read_handles(data, connection)
          STDOUT.flush
        end
      rescue e : Exception
        puts e
      end
    end
  end

  def self.handle_quit(connection)
    connection << "quit\n" if connection
    sleep 0.5
    connection.close rescue nil
    puts "\r\nExiting..".colorize.green
    exit 0
  end

  def self.special_write_handles(data, connection)
    case data
    when /c1/i
      connection << "c cold #{data.split(" ")[1]}\n" if data.is_a?(String)
      return true
    end
    false
  end

  def self.special_read_handles(data, connection)
    case data.to_s
    when /Come back soon!/i || /Leaving Alter Aeon/i
      connection.close unless connection.closed?
      puts "\nExiting".colorize.green
      exit 0
    when /pong/i
      # Ignore
    else
      print data if !data.empty?
    end
  end

  def self.login(connection, config_hash)
    connection << "#{config_hash[:username]}\n"
    sleep 0.5
    connection << "#{config_hash[:password]}\n"
    sleep 0.5
  end

  def self.keep_alive(connection)
    loop do
      sleep 60
      puts "Testing ping".colorize.blue
      buf :: UInt8[9]
      connection << "ping" if connection
      len = connection.read(buf.to_slice)
      if len > 0
        data = String.new(buf.buffer, len)
        unless data =~ /pong/i
          puts "Error in pong"
          exit 0
        end
      end
      puts "Got Pong".colorize.blue
    end
  end

  def self.get_configs
    config = TOML.parse_file("./aeon.config")
    if config.is_a?(Hash)
      main_config = config["main_configurations"]
      user_info = config["user_info"]
    else
      puts "Error parsing or loading aeon.config file"
    end
    if main_config.is_a?(Hash)
      alter_aeon_server = main_config["server"]
      alter_aeon_port = main_config["port"]
    else
      puts "Config file is missing [main_configurations] field"
    end
    if user_info.is_a?(Hash)
      username = user_info["username"]
      password = user_info["password"]
    else
      puts "Config file is missing [user_info] field"
    end
    if username.is_a?(String) && password.is_a?(String) && alter_aeon_server.is_a?(String) && alter_aeon_port.is_a?(Int)
      return {username: username, password: password, server: alter_aeon_server, port: alter_aeon_port}
    else
      puts "Error in username, password, server or port configurations"
      exit 1
    end
  end

end

AeonClient.main