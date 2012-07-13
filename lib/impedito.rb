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

require 'ncursesw'

require 'impedito/version'
require 'impedito/theme'
require 'impedito/window'

class Impedito
	def self.load (path = nil, &block)
		new.tap { |o| o.load(path, &block) }
	end

	def self.windows
		@windows ||= {}
	end

	def self.define_window (name, &block)
		windows[name] = block
	end

	attr_reader :controller, :ui

	def initialize
		@windows = {}
		@sides   = Struct.new(:left, :right)

		@theme = Theme.new {
			box {
				horizontal Ncurses::ACS_HLINE
				vertical   Ncurses::ACS_VLINE

				top {
					left  Ncurses::ACS_ULCORNER
					right Ncurses::ACS_URCORNER
				}

				bottom {
					left  Ncurses::ACS_LLCORNER
					right Ncurses::ACS_LRCORNER
				}
			}
		}
	end

	def theme (&block)
		block ? @theme.load(&block) : @theme
	end

	def load (path = nil, &block)
		if path
			instance_eval File.read(File.expand_path(path)), path
		else
			instance_exec &block
		end
	end

	def started?; !!@started; end

	def start
		return if started?

		@started = true

		Ncurses.initscr.tap {|stdscr|
			Ncurses.noecho
			Ncurses.cbreak
			Ncurses.nonl
			Ncurses.curs_set(0)

			if Ncurses.has_colors?
				Ncurses.start_color
			end

			stdscr.intrflush(false)
			stdscr.keypad(true)
		}

		trap 'WINCH' do
			adapt!
		end

		@left  = Ncurses.newwin(0, 0, 0, 0)
		@right = Ncurses.newwin(0, 0, 0, 0)

		focus(:right) and view(:playlist)
		focus(:left)  and view(:filesystem)

		dual_mode!
		ready!
		redraw!
	rescue Exception
		stop
	end

	def stop
		return unless started?

		Ncurses.delwin(@left)  if @left
		Ncurses.delwin(@right) if @right

		Ncurses.endwin

		@started = false
	end

	def ready?; @ready;        end
	def ready!; @ready = true; end

	def single_mode?; mode == :single; end
	def dual_mode?;   mode == :dual;   end

	def single_mode!
		@mode = :single

		adapt!
		render!

		self
	end

	def dual_mode!
		@mode = :dual

		adapt!
		render!

		self
	end

	def adapt!
		if single_mode?
			Ncurses.mvwin(@left, 1, 1)
			Ncurses.wresize(@left, Ncurses.LINES - 5, Ncurses.COLS - 2)
		else
			Ncurses.mvwin(@left, 1, 1)

			if Ncurses.COLS.odd?
				Ncurses.wresize(@left, Ncurses.LINES - 5, (Ncurses.COLS - 1) / 2 - 2)
				Ncurses.wresize(@right, Ncurses.LINES - 5, Ncurses.COLS / 2 - 2)
			else

			end
		end
	end

	def focus?
		@focus
	end

	def focus (side)
		raise ArgumentError, "#{side} is an unknown side" unless side == :left || side == :right

		@focus = side

		render!

		self
	end

	def toggle_focus!
		focus(focus? == :left ? :right : :left)

		self
	end

	def view (name)
		@sides[focus?] = name

		render!

		self
	end

	def render!
		return unless ready?

		Ncurses.refresh
	end

	def redraw!
		return unless ready?

		Ncurses.clear

		render!
	end
end

require 'impedito/windows/filesystem'
require 'impedito/windows/playlist'
