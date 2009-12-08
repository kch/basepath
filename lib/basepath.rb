require 'pathname'

lambda do
  return if Object.const_defined?("BASE_PATH")
  base        = Pathname.new(caller.last.sub(/:\d+$/, '')).dirname.realpath
  dotbase     = '.base'
  gotbase     = lambda { base.join(dotbase).exist? }
  base        = base.parent until base == base.parent or gotbase[]
  gotbase[] or raise "Can't find #{dotbase} for BASE_PATH"
  ::BASE_PATH = base
end.call
