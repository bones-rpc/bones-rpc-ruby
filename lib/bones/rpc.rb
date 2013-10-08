# encoding: utf-8
require 'logger'
require 'stringio'
require 'monitor'
require 'timeout'
require 'optionable'
require 'bones/rpc/errors'
require 'bones/rpc/loggable'
require 'bones/rpc/uri'
require 'bones/rpc/adapter'
require 'bones/rpc/backend'
require 'bones/rpc/parser'
require 'bones/rpc/protocol'
require 'bones/rpc/session'
require 'bones/rpc/version'

module Bones
  module RPC
    extend Loggable

    FutureValue = Struct.new(:value)
  end
end
