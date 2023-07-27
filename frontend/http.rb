#!/usr/bin/env ruby
# frozen_string_literal: true

require 'webrick'
require 'pathname'

options = {}
options[:DocumentRoot] = Pathname(__dir__).join('www')
options[:Port] = 8080

class Server < WEBrick::HTTPServer
  def service(req, res)
    super
    res['Cross-Origin-Embedder-Policy'] = 'require-corp'
    res['Cross-Origin-Opener-Policy'] = 'same-origin'
  end
end

server = Server.new(options)

trap 'INT' do server.shutdown end

server.start
