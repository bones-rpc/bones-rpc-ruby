# encoding: utf-8
module Bones
  module RPC

    # Encapsulates behaviour around addresses and resolving dns.
    #
    # @since 2.0.0
    class Address

      # @!attribute host
      #   @return [ String ] The host name.
      # @!attribute ip
      #   @return [ String ] The ip address.
      # @!attribute original
      #   @return [ String ] The original host name.
      # @!attribute port
      #   @return [ Integer ] The port.
      # @!attribute resolved
      #   @return [ String ] The full resolved address.
      attr_reader :host, :ip, :original, :path, :port

      # Instantiate the new address.
      #
      # @example Instantiate the address.
      #   Bones::RPC::Address.new("localhost:27017")
      #
      # @param [ String ] address The host:port pair as a string.
      #
      # @since 2.0.0
      def initialize(address, port = nil)
        if address.is_a?(Bones::RPC::Address)
          @host     = address.host
          @ip       = address.ip
          @original = address.original
          @port     = address.port
          @path     = address.path
          return
        end

        if port.nil?
          @original = address
        else
          @original = "#{address}:#{port}"
        end
      end

      def inspect
        "<#{self.class} \"#{to_s}\">"
      end

      def ipv4?
        ip.is_a?(Resolv::IPv4)
      end

      def ipv6?
        ip.is_a?(Resolv::IPv6)
      end

      def resolved
        if valid?
          if unix?
            "unix:#{path}"
          else
            host_string = ipv6? ? "[#{ip}]" : ip.to_s
            [host_string, port].join(':')
          end
        else
          original
        end
      end
      alias_method :to_s, :resolved

      def unix?
        path.is_a?(String)
      end

      def valid?
        unix? or (valid_ip? and valid_port?)
      end
      alias_method :connectable?, :valid?

      def valid_ip?
        ipv4? or ipv6?
      end

      def valid_port?
        !port.nil? && port != 0
      end

      # Resolve the address for the provided node. If the address cannot be
      # resolved the node will be flagged as down.
      #
      # @example Resolve the address.
      #   address.resolve(node)
      #
      # @param [ Node ] node The node to resolve for.
      #
      # @return [ String ] The resolved address.
      #
      # @since 2.0.0
      def resolve(node)
        begin
          resolve! unless valid?
          valid?
        rescue Resolv::ResolvError, SocketError => e
          node.instrument(Node::WARN, prefix: "  BONES-RPC:", message: "Could not resolve IP or UNIX path for: #{original}")
          node.down! and false
        end
      end

      def resolve!
        address = @original

        host = nil
        path = nil

        if address.is_a?(String) && port.nil?
          if !!(address =~ /\Aunix:/) # UNIX
            path = address.gsub(/\Aunix:/, '')
          elsif !!(address =~ /\A\[.+\]\:\d+\z/) # IPv6
            host, port = address.split(']:')
            host.gsub!(/\A\[/, '')
          else # IPv4 (hopefully)
            host, port = address.split(':')
          end
        end

        if path
          # Ensure path is valid
          @path = ::Socket.unpack_sockaddr_un(::Socket.pack_sockaddr_un(path))
          return
        elsif port.nil?
          raise ArgumentError, "wrong number of arguments (1 for 2)"
        else
          @host = host || address
          @port = port.to_i
        end

        # Is it an IPv4 address?
        if !!(Resolv::IPv4::Regex =~ @host)
          @ip = Resolv::IPv4.create(@host)
        end

        # Guess it's not IPv4! Is it IPv6?
        unless @ip
          if !!(Resolv::IPv6::Regex =~ @host)
            @original = "[#{@host}]:#{@port}"
            @ip = Resolv::IPv6.create(@host)
          end
        end

        # Guess it's not an IP address, so let's try DNS
        unless @ip
          addrs = Array(::Celluloid::IO::DNSResolver.new.resolve(@host))
          raise Resolv::ResolvError, "DNS result has no information for #{@host}" if addrs.empty?

          # Pseudorandom round-robin DNS support :/
          @ip = addrs[rand(addrs.size)]
        end

        if !valid_ip?
          raise ArgumentError, "unsupported address class: #{@ip.class}"
        end
      end
    end
  end
end
