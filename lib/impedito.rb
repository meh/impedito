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

require 'impedito/version'
require 'impedito/extensions'
require 'impedito/theme'
require 'impedito/window'

class Impedito
	def self.load (path = nil, &block)
		instance.tap { |o| o.load(path, &block) }
	end

	def self.windows
		instance.windows
	end

	def self.define_window (name, &block)
		instance.define_window name, &block
	end

	include Singleton

	attr_reader :controller, :mode, :input_mode

	def initialize
		@theme      = Theme.new
		@windows    = {}
		@changed    = {}
		@tick       = 0.15
		@focus      = :left
		@mode       = :dual
		@input_mode = :normal
		
		no_title_scrolling!
	end

	def load (path = nil, &block)
		if path
			instance_eval File.read(File.expand_path(path)), path
		else
			instance_exec &block
		end
	end

	def tick (value = nil)
		value ? @tick = value : @tick
	end

	def theme (&block)
		block ? @theme.set(&block) : @theme
	end

	def no_title_scrolling!
		@no_title_scrolling = true
	end

	def title_scrolling!
		@no_title_scrolling = false
	end

	def started?; !!@started; end

	def start
		return if started?

		@started = true

		Ncurses.raise_if_error {|nc|
			nc.initscr
			nc.noecho
			nc.raw
			nc.curs_set(0)

			if nc.respond_to? :ESCDELAY=
				nc.ESCDELAY = 25
			end

			if nc.has_colors?
				nc.start_color
				nc.use_default_colors
			end

			nc.stdscr.intrflush false
			nc.stdscr.keypad true
			nc.stdscr.nodelay true
		}

		@sides = {
			left: OpenStruct.new(
				raw:   Ncurses.raise_if_error(Ncurses.newwin(0, 0, 0, 0)),
				title: Title.new(nil, 0, -1)
			),

			right: OpenStruct.new(
				raw:   Ncurses.raise_if_error(Ncurses.newwin(0, 0, 0, 0)),
				title: Title.new(nil, 0, -1)
			)
		}

		theme {
			window {
				title bold: true unless title
			}

			border {
				horizontal Ncurses::ACS_HLINE unless horizontal && horizontal.value
				vertical   Ncurses::ACS_VLINE unless vertical && vertical.value

				separator {
					top    Ncurses::ACS_TTEE unless top && top.value
					left   Ncurses::ACS_RTEE unless left && left.value
					right  Ncurses::ACS_LTEE unless right && right.value
					bottom Ncurses::ACS_BTEE unless bottom && bottom.value
				}

				top {
					left  Ncurses::ACS_ULCORNER unless left && left.value
					right Ncurses::ACS_URCORNER unless right && right.value
				}

				bottom {
					left  Ncurses::ACS_LLCORNER unless left && left.value
					right Ncurses::ACS_LRCORNER unless right && right.value
				}
			}
		}

		left.window  = window(:filesystem).tap { |w| w.window(left.raw) }
		right.window = window(:playlist).tap { |w| w.window(right.raw) }

		adapt!

		left.window.redraw!
		right.window.redraw!

		ticks = 0
		while started?
			if key = Ncurses.get_key(tick)
				if key == :RESIZE
					resized!
				elsif key == :MOUSE

				else
					handle_key(key)
				end
			end

			if left.title.content != left.window.title
				left.title.content  = left.window.title
				left.title.position = 0

				changed! :left_title
			end

			if dual_mode? && right.title.content != right.window.title
				right.title.content  = right.window.title
				right.title.position = 0

				changed! :right_title
			end

			unless @no_title_scrolling
				changed! :left_title

				if dual_mode?
					changed! :right_title
				end
			end

			if @tick * ticks >= 1
				self + (@tick * ticks)

				ticks = 0
			else
				ticks += 1
			end

			render!

			Ncurses.raise_if_error {|nc|
				nc.refresh
				nc.wrefresh(left.raw)
				nc.wrefresh(right.raw) if dual_mode?
			}
		end
	rescue SystemExit
	rescue Exception => e
		Ncurses.clear
		Ncurses.printw '%s', "#{e.class.name}: #{e.message}\n"
		Ncurses.printw '%s', "#{e.backtrace.join "\n"}\n"
		Ncurses.refresh

		Ncurses.stdscr.nodelay false
		Ncurses.getch
	ensure
		Ncurses.delwin(left.raw)  if left.raw
		Ncurses.delwin(right.raw) if right.raw

		Ncurses.endwin
	end

	def stop
		return unless started?

		@started = false
	end

	def define_window (name, &block)
		@windows[name] = Window.new(name, &block)
	end

	def window (name, &block)
		win = @windows[name]
		win.instance_exec &block if block

		win
	end

	def normal_mode?;  input_mode == :normal;  end
	def command_mode?; input_mode == :command; end
	def insert_mode?;  input_mode == :insert;  end

	def single_mode?; mode == :single; end
	def dual_mode?;   mode == :dual;   end

	def single_mode!
		@mode = :single

		adapt!
		redraw!

		self
	end

	def dual_mode!
		@mode = :dual

		adapt!
		redraw!

		self
	end

	def adapt!
		if single_mode?
			Ncurses.raise_if_error {|nc|
				nc.wresize(left.raw, size.height - 5, size.width - 2)
				nc.mvwin(left.raw, 1, 1)
			}
		else
			left_width, right_width = size.width / 2, size.width / 2 + (size.width.odd? ? 1 : 0)

			Ncurses.raise_if_error {|nc|
				nc.wresize(left.raw, size.height - 5, left_width - 2)
				nc.mvwin(left.raw, 1, 1)

				nc.wresize(right.raw, size.height - 5, right_width - 2)
				nc.mvwin(right.raw, 1, left_width + 1)
			}
		end
	end

	def focus?
		@focus
	end

	def side (side)
		@sides[side]
	end

	def current
		side(focus?)
	end

	def left
		side(:left)
	end

	def right
		side(:right)
	end

	def focus (side)
		raise ArgumentError, "#{side} is an unknown side" unless side == :left || side == :right

		current.window.tap {|win|
			win.focus!
			win.render!
		}

		self
	end

	def toggle_focus!
		focus(focus? == :left ? :right : :left)

		self
	end

	def view (name)
		current.window = window(name).tap {|win|
			win.window(focus? == :left ? left.raw : right.raw)
			win.focus!
			win.redraw!
		}

		self
	end

	def + (value)

	end

	def resized!
		@size = nil

		left.window.resized!
		right.window.resized! if dual_mode?

		adapt!
		redraw!
	end

	def changed? (what)
		@changed[what] != false
	end

	def changed! (what)
		if what == :everything
			@changed.keys.each {|name|
				@changed[name] = true
			}
		else
			@changed[what] = true
		end
	end

	def rendered! (what)
		@changed[what] = false
	end

	def render!
		if single_mode?
			render_single!
		else
			render_dual!
		end

		render_statusbar!
	end

	def render_single!
		if changed? :left_border
			draw_at 0, 0, theme.border.top.left

			1.upto(size.height - 5) {|n|
				draw_at 0, n, theme.border.vertical
			}

			rendered! :left_border
		end

		if changed? :left_title
			if !current.title.content || current.title.content.empty?
				1.upto(size.width - 2) {|n|
					draw_at n, 0, theme.border.horizontal
				}
			elsif current.title.content.length >= size.width - 4
				draw_at 1, 0, theme.border.separator.left

				if @no_title_scrolling
					print_at 2, 0, "...#{current.title.content[-size.width + 4 + 3 .. -1]}", theme.window.title
				else
					width = size.width - 4
					text  = current.title.content[current.title.position .. -1]

					if current.title.spacing == -1
						current.title.spacing = width / 2
					end

					if text.empty?
						text += ' ' * current.title.spacing + current.title.content + (' ' * width)

						if (current.title.spacing -= 1) <= 0
							current.title.position = 0
							current.title.spacing  = -1
						end
					elsif text.length < width / 2
						text += ' ' * (width / 2) + current.title.content[0 .. width - text.length]

						current.title.position += 1
					else
						text += ' ' * width

						current.title.position += 1
					end

					print_at 2, 0, text[0, width], theme.window.title
				end

				draw_at size.width - 2, 0, theme.border.separator.right
			else
				first  = (size.width - 2) / 2 - (current.title.content.length + 2) / 2
				second = first + current.title.content.length + 1

				if size.width - second >= first + 3
					first  += 1
					second += 1
				end

				1.upto(first) {|n|
					draw_at n, 0, theme.border.horizontal
				}

				draw_at first, 0, theme.border.separator.left
				print_at first + 1, 0, current.title.content, theme.window.title
				draw_at second, 0, theme.border.separator.right

				(second + 1).upto(size.width - 2) {|n|
					draw_at n, 0, theme.border.horizontal
				}
			end

			rendered! :left_title
		end

		left.window.render!

		if changed? :right_border
			draw_at size.width - 1, 0, theme.border.top.right

			1.upto(size.height - 5) {|n|
				draw_at size.width - 1, n, theme.border.vertical
			}

			rendered! :right_border
		end
	end

	def render_dual!
		if changed? :left_border
			draw_at 0, 0, theme.border.top.left

			1.upto(size.height - 5) {|n|
				draw_at 0, n, theme.border.vertical
			}

			rendered! :left_border
		end

		if changed? :left_title
			width = left.window.size.width + 2

			if !left.title.content || left.title.content.empty?
				1.upto(width - 2) {|n|
					draw_at n, 0, theme.border.horizontal
				}
			elsif left.title.content.length >= width - 4
				draw_at 1, 0, theme.border.separator.left

				if @no_title_scrolling
					print_at 2, 0, "...#{left.title.content[-width + 4 + 3 .. -1]}", theme.window.title
				else
					width = width - 4
					text  = left.title.content[left.title.position .. -1]

					if left.title.spacing == -1
						left.title.spacing = width / 2
					end

					if text.empty?
						text += ' ' * left.title.spacing + left.title.content + (' ' * width)

						if (left.title.spacing -= 1) <= 0
							left.title.position = 0
							left.title.spacing  = -1
						end
					elsif text.length < width / 2
						text += ' ' * (width / 2) + left.title.content[0 .. width - text.length]

						left.title.position += 1
					else
						text += ' ' * width

						left.title.position += 1
					end

					print_at 2, 0, text[0, width], theme.window.title
				end

				draw_at size.width - 2, 0, theme.border.separator.right
			else
				first  = (width - 2) / 2 - (left.title.content.length + 2) / 2
				second = first + left.title.content.length + 1

				if width - second >= first + 3
					first  += 1
					second += 1
				end

				1.upto(first) {|n|
					draw_at n, 0, theme.border.horizontal
				}

				draw_at first, 0, theme.border.separator.left
				print_at first + 1, 0, left.title.content, theme.window.title
				draw_at second, 0, theme.border.separator.right

				(second + 1).upto(width - 2) {|n|
					draw_at n, 0, theme.border.horizontal
				}
			end

			rendered! :left_title
		end

		left.window.render!

		if changed? :center_border
			offset = left.window.size.width + 1

			draw_at offset, 0, theme.border.top.right

			1.upto(size.height - 5) {|n|
				draw_at offset, n, theme.border.vertical
			}

			draw_at offset + 1, 0, theme.border.top.left

			1.upto(size.height - 5) {|n|
				draw_at offset + 1, n, theme.border.vertical
			}

			rendered! :center_border
		end

		if changed? :right_title
			width  = right.window.size.width + 2
			offset = left.window.size.width + 2

			if !right.title.content || right.title.content.empty?
				1.upto(width - 2) {|n|
					draw_at offset + n, 0, theme.border.horizontal
				}
			elsif right.title.content.length >= width - 4
				draw_at 1, 0, theme.border.separator.right

				if @no_title_scrolling
					print_at 2, 0, "...#{right.title.content[-width + 4 + 3 .. -1]}", theme.window.title
				else
					width = width - 4
					text  = right.title.content[right.title.position .. -1]

					if right.title.spacing == -1
						right.title.spacing = width / 2
					end

					if text.empty?
						text += ' ' * right.title.spacing + right.title.content + (' ' * width)

						if (right.title.spacing -= 1) <= 0
							right.title.position = 0
							right.title.spacing  = -1
						end
					elsif text.length < width / 2
						text += ' ' * (width / 2) + right.title.content[0 .. width - text.length]

						right.title.position += 1
					else
						text += ' ' * width

						right.title.position += 1
					end

					print_at 2, 0, text[0, width], theme.window.title
				end

				draw_at size.width - 2, 0, theme.border.separator.right
			else
				first  = (width - 2) / 2 - (right.title.content.length + 2) / 2
				second = first + right.title.content.length + 1

				if width - second >= first + 3
					first  += 1
					second += 1
				end

				1.upto(first) {|n|
					draw_at offset + n, 0, theme.border.horizontal
				}

				draw_at offset + first, 0, theme.border.separator.left
				print_at offset + first + 1, 0, right.title.content, theme.window.title
				draw_at offset + second, 0, theme.border.separator.right

				(second + 1).upto(width - 2) {|n|
					draw_at offset + n, 0, theme.border.horizontal
				}
			end

			rendered! :right_title
		end

		right.window.render!

		if changed? :right_border
			draw_at size.width - 1, 0, theme.border.top.right

			1.upto(size.height - 5) {|n|
				draw_at size.width - 1, n, theme.border.vertical
			}

			rendered! :right_border
		end
	end

	def render_statusbar!

	end

	def redraw!
		Ncurses.clear

		left.window.redraw!
		right.window.redraw! if dual_mode?

		changed! :everything
		render!
	end

	Size  = Struct.new(:width, :height)
	Title = Struct.new(:content, :position, :spacing)

	def size
		@size ||= Size.new(Ncurses.COLS, Ncurses.LINES)
	end

	def draw_at (x, y, element)
		Ncurses.move(y, x)
		Ncurses.attron(element.to_i)

		if element.value.is_a? Integer
			Ncurses.addch element.value
		else
			Ncurses.addstr element.value.to_s
		end

		Ncurses.attroff(element.to_i)
	end

	def print_at (x, y, string, element = theme.default)
		Ncurses.move(y, x)
		Ncurses.attron(element.to_i)

		Ncurses.addstr string.to_s

		Ncurses.attroff(element.to_i)
	end

	def handle_key (key)
		exit if key == :q

		print_at 2, 2, key.inspect << '                               '
	end
end

require 'impedito/windows/filesystem'
require 'impedito/windows/playlist'
