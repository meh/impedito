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

class Window
	class Widget
		def changed!
			@changed = true

			self
		end

		def rendered!
			@changed = false

			self
		end

		def changed?
			!!@changed
		end
	end

	attr_reader :name

	def initialize (name, &block)
		@name     = name
		@widgets  = []

		instance_exec &block
	end

	def title (value = nil)
		return @title unless value

		@title = value
	end

	def window (window)
		@window = window
		@widgets.each(&:changed!)
	end

	def scroll (lines)
	end

	def focus!
		
	end

	def resized!
		@size = nil

		redraw!
	end

	def changed?
		@widgets.any?(&:changed?)
	end

	def render!
		Ncurses.waddstr(@window, @name.to_s[0] * 1024)

		return unless changed?

		@widgets.each(&:render!)

		Ncurses.wrefresh(@window)
	end

	def redraw!
		Ncurses.wclear(@window)

		@widgets.each(&:changed!)

		render!
	end

	Size = Struct.new(:width, :height)

	def size
		@size ||= (x = []; y = []; Ncurses.getmaxyx(@window, y, x); Size.new(x.first, y.first))
	end
end

end
