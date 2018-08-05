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

# rubocop:disable Metrics/AbcSize

module Heeler
  # Used to parse the HTTP request.
  class Parser < BasicObject
    # Parse the HTTP data stream.
    #
    # @param [ String ] data The HTTP request as a string.
    #
    # @return [ Heeler::Request ]
    def parse_request(data)
      req                        = Request.new
      head, host_port, *tail     = data.split(CRLF)
      method, path_query, schema = head.split(' ')
      path, query                = path_query.split('?')
      host, port                 = host_port[6..-1].split(':')

      req.method = method
      req.path   = path
      req.query  = query
      req.schema = schema
      req.host   = host
      req.port   = port

      tail.each { |e| req.headers.store(*e.split(SEP)) }

      req
    end
  end
end

# rubocop:enable Metrics/AbcSize
