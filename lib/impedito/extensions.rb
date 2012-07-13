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

module Ncurses
	require 'ncursesw'

	class Executor < BasicObject
		def method_missing (id, *args)
			result = ::Ncurses.__send__(id, *args)
			
			if result == ::Ncurses::ERR
				raise "#{id}(#{args.map(&:inspect).join ', '}) failed"
			end

			result
		end
	end

	def self.raise_if_error (value = nil, &block)
		raise if value == Ncurses::ERR

		return value unless block

		block.call(Executor.new)
	end

	class Key
		attr_reader :points

		def initialize (value, alt = false, ctrl = false, shift = false, points = [])
			@value  = value
			@alt    = alt
			@ctrl   = ctrl
			@shift  = shift
			@points = points
		end

		def alt?;   @alt;   end
		def ctrl?;  @ctrl;  end
		def shift?; @shift; end

		def == (other)
			super || to_s == other || to_sym == other
		end

		def to_s
			@value.to_s
		end

		def to_sym
			@value.to_sym
		end

		def inspect
			"#<#{self.class.name}(#{points.join ' '}): #{to_s}#{' alt' if alt?}#{' ctrl' if ctrl?}#{' shift' if shift?}>"
		end

		Map = {
			Ncurses::KEY_DOWN      => :DOWN,
			Ncurses::KEY_UP        => :UP,
			Ncurses::KEY_LEFT      => :LEFT,
			Ncurses::KEY_SLEFT     => :LEFT,
			Ncurses::KEY_RIGHT     => :RIGHT,
			Ncurses::KEY_SRIGHT    => :RIGHT,
			Ncurses::KEY_HOME      => :HOME,
			Ncurses::KEY_SHOME     => :HOME,
			Ncurses::KEY_BACKSPACE => :BACKSPACE,
			Ncurses::KEY_BACKSPACE => :BACKSPACE,
			Ncurses::KEY_DL        => :DELETE_LINE,
			Ncurses::KEY_SDL       => :DELETE_LINE,
			Ncurses::KEY_IL        => :INSERT_LINE,
			Ncurses::KEY_DC        => :DELETE,
			Ncurses::KEY_SDC       => :DELETE,
			Ncurses::KEY_IC        => :INSERT,
			Ncurses::KEY_SIC       => :INSERT,
			Ncurses::KEY_CLEAR     => :CLEAR,
			Ncurses::KEY_EOS       => :CLEAR_TO_END_OF_SCREEN,
			Ncurses::KEY_EOL       => :CLEAR_TO_END_OF_LINE,
			Ncurses::KEY_SEOL      => :CLEAR_TO_END_OF_LINE,
			Ncurses::KEY_SF        => :SCROLL_FORWARD,
			Ncurses::KEY_SR        => :SCROLL_BACKWARD,
			Ncurses::KEY_NPAGE     => :PAGDOWN,
			Ncurses::KEY_PPAGE     => :PAGUP,
			Ncurses::KEY_STAB      => :SET_TAB,
			Ncurses::KEY_CTAB      => :CLEAR_TAB,
			Ncurses::KEY_CATAB     => :CLEAR_ALL_TABS,
			Ncurses::KEY_ENTER     => :ENTER,
			Ncurses::KEY_PRINT     => :PRINT,
			Ncurses::KEY_SPRINT    => :PRINT,
			Ncurses::KEY_LL        => :HOME,
			Ncurses::KEY_A1        => :UP_LEFT,
			Ncurses::KEY_A3        => :UP_RIGHT,
			Ncurses::KEY_B2        => :CENTER,
			Ncurses::KEY_C1        => :DOWN_LEFT,
			Ncurses::KEY_C3        => :DOWN_RIGHT,
			Ncurses::KEY_BTAB      => :BACK_TAB,
			Ncurses::KEY_BEG       => :BEGIN,
			Ncurses::KEY_SBEG      => :BEGIN,
			Ncurses::KEY_CANCEL    => :CANCEL,
			Ncurses::KEY_SCANCEL   => :CANCEL,
			Ncurses::KEY_CLOSE     => :CLOSE,
			Ncurses::KEY_COMMAND   => :COMMAND,
			Ncurses::KEY_SCOMMAND  => :COMMAND,
			Ncurses::KEY_COPY      => :COPY,
			Ncurses::KEY_SCOPY     => :COPY,
			Ncurses::KEY_CREATE    => :CREATE,
			Ncurses::KEY_SCREATE   => :CREATE,
			Ncurses::KEY_END       => :END,
			Ncurses::KEY_SEND      => :END,
			Ncurses::KEY_EXIT      => :EXIT,
			Ncurses::KEY_SEXIT     => :EXIT,
			Ncurses::KEY_FIND      => :FIND,
			Ncurses::KEY_SFIND     => :FIND,
			Ncurses::KEY_HELP      => :HELP,
			Ncurses::KEY_SHELP     => :HELP,
			Ncurses::KEY_SMOVE     => :MARK,
			Ncurses::KEY_MESSAGE   => :MESSAGE,
			Ncurses::KEY_SMESSAGE  => :MESSAGE,
			Ncurses::KEY_MOVE      => :MOVE,
			Ncurses::KEY_NEXT      => :NEXT,
			Ncurses::KEY_SNEXT     => :NEXT,
			Ncurses::KEY_OPEN      => :OPEN,
			Ncurses::KEY_OPTIONS   => :OPTIONS,
			Ncurses::KEY_SOPTIONS  => :OPTIONS,
			Ncurses::KEY_PREVIOUS  => :PREVIOUS,
			Ncurses::KEY_SPREVIOUS => :PREVIOUS,
			Ncurses::KEY_REDO      => :REDO,
			Ncurses::KEY_SREDO     => :REDO,
			Ncurses::KEY_REFERENCE => :REFERENCE,
			Ncurses::KEY_REFRESH   => :REFRESH,
			Ncurses::KEY_REPLACE   => :REPLACE,
			Ncurses::KEY_SREPLACE  => :REPLACE,
			Ncurses::KEY_RESTART   => :RESTART,
			Ncurses::KEY_RESUME    => :RESUME,
			Ncurses::KEY_SRSUME    => :RESUME,
			Ncurses::KEY_SAVE      => :SAVE,
			Ncurses::KEY_SSAVE     => :SAVE,
			Ncurses::KEY_SELECT    => :SELECT,
			Ncurses::KEY_SUSPEND   => :SUSPEND,
			Ncurses::KEY_SSUSPEND  => :SUSPEND,
			Ncurses::KEY_UNDO      => :UNDO,
			Ncurses::KEY_SUNDO     => :UNDO,

			513 => :DOWN,
			527 => :UP,

			Shift: [
				Ncurses::KEY_SLEFT, Ncurses::KEY_SRIGHT, 513, 527,
				Ncurses::KEY_SHOME, Ncurses::KEY_SDL, Ncurses::KEY_SDC, Ncurses::KEY_SIC,
				Ncurses::KEY_SEOL, Ncurses::KEY_SPRINT, Ncurses::KEY_SBEG, Ncurses::KEY_SCANCEL,
				Ncurses::KEY_SCOMMAND, Ncurses::KEY_SCOPY, Ncurses::KEY_SCREATE, Ncurses::KEY_SEND,
				Ncurses::KEY_SEXIT, Ncurses::KEY_SFIND, Ncurses::KEY_SHELP, Ncurses::KEY_SMOVE,
				Ncurses::KEY_SMESSAGE, Ncurses::KEY_SNEXT, Ncurses::KEY_SOPTIONS,
				Ncurses::KEY_SPREVIOUS, Ncurses::KEY_SREDO, Ncurses::KEY_SREPLACE,
				Ncurses::KEY_SRSUME, Ncurses::KEY_SSAVE, Ncurses::KEY_SSUSPEND, Ncurses::KEY_SUNDO
			]
		}
	end

	def self.get_key (timeout = nil)
		if timeout
			readable, = IO.select([STDIN], nil, nil, timeout)
		end

		value = Ncurses.getch

		if value < 0
			return
		elsif value == Ncurses::KEY_RESIZE
			return :RESIZE
		elsif value == Ncurses::KEY_MOUSE
			return :MOUSE
		end

		points = [value]
		alt    = false
		ctrl   = false
		shift  = false

		if value == 27
			value = :ESC
		elsif value <= 32
			if value == 10
				value = :ENTER
			elsif value == 9
				value = :TAB
			elsif value == 32
				value = :SPACE
			elsif value < 26
				value = (value + 64).chr
				ctrl  = true
			else
				value = value.chr
				ctrl  = true
			end
		else
			if value == 127
				value = :BACKSPACE
			elsif tmp = Key::Map[value]
				shift = Key::Map[:Shift].include?(value)
				value = tmp
			elsif (0410  ..  0507) === value
				value = :"F#{value - 0410}"
			else
				''.force_encoding('BINARY').tap {|string|
					if value >> 7 == 0
						string.concat(value)

						if ('A'  ..  'Z') === string
							shift = true
						end
					elsif value >> 5 == 6
						string.concat(value)
						string.concat(Ncurses.getch.tap { |n| return -1 if n == -1; points << n })
					elsif value >> 4 == 14
						string.concat(value)
						string.concat(Ncurses.getch.tap { |n| return -1 if n == -1; points << n })
						string.concat(Ncurses.getch.tap { |n| return -1 if n == -1; points << n })
					elsif value >> 3 == 30
						string.concat(value)
						string.concat(Ncurses.getch.tap { |n| return -1 if n == -1; points << n })
						string.concat(Ncurses.getch.tap { |n| return -1 if n == -1; points << n })
						string.concat(Ncurses.getch.tap { |n| return -1 if n == -1; points << n })
					end

					value = string.force_encoding('UTF-8')
				} rescue nil
			end
		end

		Key.new(value, alt, ctrl, shift, points)
	end
end

class String
	require 'unicode_utils'

	def display_size
		UnicodeUtils.display_width(self)
	end

	alias display_length display_size
end

require 'ostruct'
require 'singleton'
require 'mpd'
