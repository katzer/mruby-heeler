# MIT License
#
# Copyright (c) 2018 Sebastian Katzer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module Heeler
  # Forks the process for each incoming request.
  class Server
    # Initializes the server via a config hash map.
    #
    # @param [ Proc ]                 app    The shelf app.
    # @param [ Hash<Symbol, Object> ] config Settings like :port or :host
    #
    # @return [ Void ]
    def initialize(app, config = {})
      @config  = config.dup
      @app     = app
      @parser  = Parser.new
      @sigpipe = Socket.const_defined?(:SO_NOSIGPIPE)
    end

    # The passed config hash.
    #
    # @return [ Hash ]
    attr_reader :config

    # The host name or ip address where to connect.
    #
    # @return [ String ]
    def host
      config[:host]
    end

    # The port where to listen.
    #
    # @return [ Integer ]
    def port
      (config[:port] || 8080).to_i
    end

    # If receiving data over the socket should block or not.
    #
    # @return [ Boolean ]
    def nonblock?
      config[:nonblock] != false
    end

    # The timeout how long to wait for incomming data.
    #
    # @return [ Integer ]
    def timeout
      [0, config[:timeout] || 5].max
    end

    # Bind to the host and port and wait for incomming connections.
    #
    # @return [ Void ]
    def run
      tcp = TCPServer.new(host, port)

      GC.start
      keep_clean(config[:cleanup_interval] || 5)

      while (io = accept(tcp))
        fork { handle(io) } && close(io)
      end
    ensure
      stop_cleanup
    end

    private

    # Receive the request, call the app to the a response and send it back to.
    #
    # @param [ BasicSocket ] io The tcp socket from where to read the data.
    #
    # @return [ Void ]
    def handle(io)
      data = recv(io)
      res  = exec parse data if data
    ensure
      send(io, res)
      GC.start if config[:run_gc_per_request]
    end

    # Wait for incoming socket connection.
    #
    # @param [ TCPServer ] tcp       The TCP server which is bind to a port.
    # @param [ Integer ]   max_retry Max attemps for sysaccept.
    #                                Defaults to: 10
    #
    # @return [ BasicSocket ]
    def accept(tcp, max_retry = 10)
      counter = counter ? counter + 1 : 1
      io      = BasicSocket.for_fd(tcp.sysaccept)
    rescue RuntimeError => e
      counter <= max_retry ? retry : raise(e)
    ensure
      io.setsockopt(Socket::SOL_SOCKET, Socket::SO_NOSIGPIPE, true) if @sigpipe
    end

    # Receive data from the socket in a loop until all data have been received.
    # Might break out of the loop in case of a timeout.
    #
    # @param [ BasicSocket ] io The tcp socket from where to read the data.
    #
    # @return [ String ] nil if no data could be read.
    def recv(io)
      data = nil
      time = Time.now if nonblock?

      loop do
        buf = io.recv(RECV_BUF, nonblock? ? Socket::MSG_DONTWAIT : 0)

        data ? (data += buf) : (data = buf)

        return data if buf.bytesize != RECV_BUF
      rescue RuntimeError
        (Time.now - time) < timeout ? retry : return
      end
    end

    # Parse the HTTP request into a shelf request.
    #
    # @param [ String ] data The data reveiced from the socket.
    #
    # @return [ Hash ]
    def parse(data)
      req = @parser.parse_request(data)

      req.headers.merge(
        REQUEST_METHOD => req.method,
        PATH_INFO      => req.path || '/',
        QUERY_STRING   => req.query
      )
    end

    # Pass the env to the shelf app and return the HTTP response string.
    #
    # @param [ Hash ] env The parsed Shelf env object.
    #
    # @return [ String ]
    def exec(env)
      code, headers, body = @app.call(env)

      headers[CONNECTION] = CLOSE
      headers[SERVER]     = HEELER

      header = headers.reduce('') { |s, p| "#{s}#{p[0]}:#{p[1]}#{CRLF}" }

      "#{http_status_line(code)}#{CRLF}#{header}#{CRLF}#{body.join}"
    end

    # Send data back to the client.
    #
    # @param [ BasicSocket ] io   The tcp socket where to send the data.
    # @param [ String ]      data The data to send.
    #
    # @return [ String ]
    def send(io, data)
      while data
        n = io.syswrite(data)
        return if n == data.bytesize
        data = data[n..-1]
      end
    rescue RuntimeError
      raise 'Connection reset by peer' if config[:debug] && io.closed?
    ensure
      close(io)
    end

    # Close the socket from server side.
    #
    # @param [ BasicSocket ] io The tcp socket to close.
    #
    # @return [ Void ]
    def close(io)
      io.close
    rescue RuntimeError
      nil
    end

    # Return the HTTP status line including the HTTP version, response code
    # and short description.
    #
    # @param [ Fixnum ] code The HTTP status code.
    #                        Defaults to: 200 (OK)
    #
    # @return [ String ]
    def http_status_line(code = 200)
      "HTTP/1.1 #{code} #{HTTP_STATUS_CODES[code]}"
    end
  end
end
