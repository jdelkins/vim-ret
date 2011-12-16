require 'ret/fileset'

module Ret
  class Controller
    # mode can be :dir or :tree
    attr_reader :mode
    attr_reader :cwd

    @@last_mode = :dir
    
    def initialize()
      @view = Ret::View.new()
    end

    def invoke(path)
      @fileset = Ret::Fileset.new(path)
      @view.init_buffer
      @mode.mode = @@last_mode
    end

    def mode=(newmode)
      if not [:dir, :tree].include?(newmode)
        raise ArgumentError, "change_mode: mode must be :dir or :tree"
      end
      if newmode != @mode
        @mode = newmode
        @@last_mode = newmode
        self.rebase(@cwd)
      end
    end

    def rebase()
    end

  end
end
