require 'pathname'

module Basepath
  extend self

  def mine(file = false)
    path_to_first_caller = (s = caller.last) ? s.sub(/:\d+(?::in `.*?')?$/, '') : __FILE__
    path = Pathname.new(path_to_first_caller).realpath
    file ? path : path.dirname
  end

  # used when setting consts and load_path
  def const_expand!(s)
    (s.sub!(RX_CONSTS, '') ? Object.const_get($1) : ::BASE_PATH).join(s);
  end
end

lambda do
  return if Object.const_defined?("BASE_PATH")
  # find and set base
  first_path    = (s = caller.last) ? s.sub(/:\d+(?::in `.*?')?$/, '') : __FILE__ # file is just for when basepath is called directly
  # handles irb, general pwd cases. TODO: write decent code later
  cur_path      = Pathname.new(Dir.pwd) if defined?(IRB) || defined?(Rake) || defined?(Thin)
  cur_path    ||= Pathname.new(first_path).dirname.realpath
  dot_base      = '.base'
  got_base      = lambda { cur_path.join(dot_base).exist? }
  cur_path      = cur_path.parent until cur_path == cur_path.parent or got_base[]
  ::BASE_PATH   = got_base[] ? cur_path : raise("Can't find #{dot_base} for BASE_PATH. (started at #{first_path})")

  # read dot_base
  base_conf = IO.read(::BASE_PATH.join(dot_base)).strip.gsub(/[ \t]/, '').gsub(/\n+/, "\n")\
    .scan(/^\[(\w+)\]((?:\n[^\[].*)*)/)\
    .inject(Hash.new('')) { |h, (k, s)| h[k.to_sym] = s.strip; h }
  base_conf.values.each { |s| s.gsub!(/\s*#.*\n/, "\n") }

  # set path consts
  k_order   = [] # ruby 1.8 doesn't retain hash key order
  consts    = base_conf[:consts].scan(/([A-Z][A-Z0-9_]*)=(.+)/).inject({}) { |h, (k, v)| k_order << k; h[k] = v; h }
  RX_CONSTS = /^(#{consts.keys.map(&Regexp.method(:escape)).join('|')})(?:\/|$)/
  k_order.each { |k| Object.const_set(k, Basepath.const_expand!(consts[k])) }

  # set load_paths
  load_paths = base_conf[:load_paths].split("\n").map { |s|
    Dir[Basepath.const_expand!(s).to_s] }.flatten.select { |s|
      File.directory? s }
  $LOAD_PATH.unshift(*load_paths)

  # requires
  loaded = caller(0).map { |s| s[/\A(.+?)(?:\.rb)?:\d+(?::in `.*?')?\z/, 1] }.compact.uniq
  globs, names = base_conf[:requires].split("\n").partition { |s| s =~ /\*/ }
  names.concat \
    globs.map { |s| Dir[Basepath.const_expand!(s).to_s + ".rb"] }\
      .flatten.select { |s| File.file? s }.map { |s| s.sub(/\.rb$/, '') }
  names.each { |lib| require lib }

  # includes
  base_conf[:includes].split("\n").each { |k| include Object.const_get(k.strip) }
end.call
