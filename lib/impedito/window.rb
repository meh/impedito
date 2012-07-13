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

class Impedito; class UI

class Window
	attr_reader :name

	def initialize (name, &block)
		@name = name

		instance_exec &block
	end

	def scroll (lines)
	end

	def render! (window)
		Ncurses.wrefresh(window)
	end

	def redraw! (window)
		Ncurses.wclear(window)

		render!(window)
	end
end

end; end
