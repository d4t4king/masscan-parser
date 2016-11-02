
require 'rexml/document'

begin
	require 'open3'
rescue LoadError
end

begin
	require 'rubygems'
	require 'blinkenlights'
rescue LoadError
end

module Masscan
	module XmlParsing
	end
end

class Masscan::Parser
	# raw xml output from the scan
	attr_reader :rawxml
	# session object for the scan
	attr_reader :session

	# Major version number
	Major = 0
	# Minor version number
	Minor = 0
	# Teeny version numebr
	Teeny = 1
	# development stage (currently "development" or "release")
	Stage = "development"
	# Pre-built version string
	Version = "#{Major}.#{Minor}.#{Teeny}"

	["file", "read", "scan", "string"].each do |name|
		meth = "parse#{name}"
		self.class_eval("
			def self.#{meth}(*args)
				parser = self.new
				parser.#{meth}(*args)
				yield parser if block_given?
				parser
			end
		")
	end

	def parseread(obj)
		if not obj.respond_to?(:read)
			raise TypeError, "Passwd object must respond to read()"
		end

		parsestring(obj.read)
	end

	def parsefile(filename)
		File.open(filename) { |f| parseread(f) }
	rescue
		raise $!.class, "Error parsing \"#{filename}\": #{$!}"
	end

	def parsestring(str)
		if not str.respond_to?(:to_str)
			raise TypeError, "XML data should be a String, or must respond to to_str()"
		end

		parse(str.to_str)
	end

	def parsescan(masscan, args, targets = [])
		if args =~ /\s-o|^-o/
			raise ArgumentError, "Output option (-o*) passed to parsescan()"
		end

		command = "#{masscan} -d -oX - #{args} #{targets.join(" ")}"

		begin
			Open3.popen3(command) do |sin, sout, serr|
				parseread(sout)
			end
		rescue NameError
			IO.popen(command) do |io|
				parseread(io)
			end
		end
	end

	def hosts(status = "")
		@hosts.map { |host|
			if status.empty? or host.status == status
				yield host if block_given?
				host
			end
		}.compact
	end

	def host(hostip)
		@hosts.find do |host|
			host.addr == hostip or host.hostname == hostip
		end
	end

	alias get_host host

	
end

