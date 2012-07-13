#--
# Copyleft meh. [http://meh.paranoid.pk | meh@paranoici.org]
#
# This file is part of impedito.
#
# impedito is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# impedito is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with impedito. If not, see <http://www.gnu.org/licenses/>.
#++

class Impedito

class Theme
	class Element
		attr_reader :foreground, :background, :attributes, :value

		def initialize (*args)
			@foreground, @background, @attributes, @value = args
		end

		alias fg foreground

		alias bg background

		alias attr  attributes
		alias attrs attributes

		%w[bold standout underline reverse blink].each {|name|
			name = name.to_sym

			define_method "#{name}?" do
				return false unless attributes

				attributes.include? name.to_sym
			end
		}
	end

	class Group
		attr_reader :name

		def initialize (name, &block)
			@name   = name
			@pieces = {}

			load &block
		end

		def method_missing (id, *args, &block)
			return @pieces[id] if args.empty? && !block

			if block
				@pieces[id] = Group.new(id, &block)
			else
				data = args.last.is_a?(Hash) ? args.pop : {}

				@pieces[id] = Element.new(
					data[:fg] || data[:foreground],
					data[:bg] || data[:background],
					data[:attr] || data[:attrs] || data[:attributes],
					args.shift
				)
			end

			self
		end

		def load (path = nil, &block)
			if path
				instance_eval File.read(File.expand_path(path)), path
			else
				instance_exec &block
			end
		end
	end

	def initialize (&block)
		@root = Group.new(:root, &block)
	end

	def method_missing (id, *args, &block)
		@root.__send__ id, *args, &block
	end
end

end
