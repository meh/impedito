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
	Colors = {
		8 => {
			black:    0,
			darkgray: 0,

			red:      1,
			lightred: 1,

			green:      2,
			lightgreen: 2,

			brown:  3,
			yellow: 3,

			blue:      4,
			lightblue: 4,

			magenta:      5,
			purple:       5,
			lightmagenta: 5,

			cyan:      6,
			lightcyan: 6,

			lightgray: 7,
			white:     7,

			bold: [:darkgray, :lightred, :yellow, :lightblue, :lightmagenta, :lightcyan, :white]
		},

		16 => {
			black:        0,
			red:          1,
			green:        2,
			brown:        3,
			blue:         4,
			magenta:      5,
			purple:       5,
			cyan:         6,
			lightgray:    7,
			darkgray:     8,
			lightred:     9,
			lightgreen:   10,
			yellow:       11,
			lightblue:    12,
			lightmagenta: 13,
			lightcyan:    14,
			white:        15
		}
	}
	def self.color_for (what)
		return -1 if what.nil?

		if Ncurses.COLORS == 256 || Ncurses.COLORS == 16
			Colors[16][what.to_sym.downcase] or raise ArgumentError, 'unknown color name'
		else
			Colors[8][what.to_sym.downcase]
		end
	end

	def self.needs_bold? (what)
		Ncurses.COLORS == 8 ? Colors[:bold].include?(what.to_sym.downcase) : false
	end

	class Element
		attr_reader :group, :name
		attr_writer :foreground, :background, :attributes, :value

		def initialize (group, name, *args)
			@group = group
			@name  = name

			@foreground, @background, @attributes, @value = args
		end

		def foreground
			return @foreground if @foreground || name == :default

			@group.default.foreground
		end

		def background
			return @background if @background || name == :default

			@group.default.background
		end

		def attributes
			return @attributes if @attributes || name == :default

			@group.default.attributes
		end

		def value
			return @value if @value || name == :default

			@group.default.value
		end

		def theme
			@group.theme
		end

		alias fg foreground

		alias bg background

		alias attr  attributes
		alias attrs attributes

		def normal?
			attributes && attributes.empty?
		end

		%w[standout underline reverse blink dim bold].each {|name|
			name = name.to_sym

			define_method "#{name}?" do
				return false unless attributes

				attributes.include? name.to_sym
			end
		}

		def to_i
			result = theme.color(foreground, background)

			result |= Ncurses::A_STANDOUT  if standout?
			result |= Ncurses::A_UNDERLINE if underline?
			result |= Ncurses::A_REVERSE   if reverse?
			result |= Ncurses::A_BLINK     if blink?
			result |= Ncurses::A_DIM       if dim?
			result |= Ncurses::A_BOLD      if bold? || Theme.needs_bold?(foreground)

			result
		end

		def inspect
			"#<#{self.class.name}(#{name}, #{group.name}):#{" value=#{value}" if value}#{" fg=#{foreground}" if foreground}#{" bg=#{background}" if background}#{" attrs=#{attributes}" if attributes}>"
		end
	end

	class Group
		attr_reader :group, :name

		def initialize (owner, name, &block)
			if owner.is_a? Theme
				@theme = owner
			else
				@group = owner
			end

			@name   = name
			@pieces = {}

			set &block if block
		end

		def theme
			@theme || @group.theme
		end

		def root?
			!group
		end

		def default (*args)
			method_missing(:default, *args) || (@group ? @group.default : Element.new(self, :default))
		end

		def method_missing (id, *args, &block)
			return @pieces[id] if args.empty? && !block

			if block
				if @pieces[id] && !@pieces[id].is_a?(Group)
					raise ArgumentError, "#{id} is already an element"
				end

				@pieces[id] ||= Group.new(self, id, &block)
				@pieces[id].set(&block)
			else
				data = args.last.is_a?(Hash) ? args.pop : {}

				if element = @pieces[id]
					if tmp = data[:fg] || data[:foreground]
						element.foreground = tmp
					end

					if tmp = data[:bg] || data[:background]
						element.background = tmp
					end

					if tmp = data[:attr] || data[:attrs] || data[:attributes]
						element.attributes = tmp
					end

					if tmp = args.shift
						element.value = tmp
					end
				else
					attributes = data[:attr] || data[:attrs] || data[:attributes] || []
					attributes << :standout  if data[:standout]
					attributes << :underline if data[:underline]
					attributes << :reverse   if data[:reverse]
					attributes << :blink     if data[:blink]
					attributes << :dim       if data[:dim]
					attributes << :bold      if data[:bold]

					@pieces[id] = Element.new(self, id,
						data[:fg] || data[:foreground],
						data[:bg] || data[:background],
						attributes.empty? ? nil : attributes,
						args.shift
					)
				end
			end

			self
		end

		def set (path = nil, &block)
			if path
				instance_eval File.read(File.expand_path(path)), path
			else
				instance_exec &block
			end
		end

		def elements
			@pieces.values.map {|piece|
				piece.is_a?(Group) ? piece.elements : piece
			}.flatten
		end
	end

	def initialize (&block)
		@root  = Group.new(self, nil, &block)
		@pairs = {}

		set &block if block
	end

	def respond_to_missing? (id, include_private = false)
		@root.respond_to? id, include_private
	end

	def method_missing (id, *args, &block)
		@root.__send__ id, *args, &block
	end

	def pair_for (foreground, background)
		foreground = Theme.color_for(foreground) unless foreground.is_a?(Integer)
		background = Theme.color_for(background) unless background.is_a?(Integer)

		[foreground, background]
	end

	def color (foreground, background)
		pair = pair_for(foreground, background)

		update! unless @pairs.member? pair

		Ncurses.COLOR_PAIR(@pairs[pair])
	end

	def update!
		@pairs.clear

		elements.map { |e| pair_for(e.foreground, e.background) }.uniq.each.with_index {|pair, index|
			Ncurses.init_pair(@pairs[pair] = index + 1, *pair)
		}
	end
end

end
