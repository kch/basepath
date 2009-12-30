require 'pathname'

module Basepath
  extend self

  def mine(file = false)
    path_to_first_caller = (s = caller.last) ? s.sub(/:\d+(?::in `.*?')?$/, '') : __FILE__
    path = Pathname.new(path_to_first_caller).realpath
    file ? path : path.dirname
  end
end

lambda do
  return if Object.const_defined?("BASE_PATH")

  # find and set base
  first_path  = (s = caller.last) ? s.sub(/:\d+(?::in `.*?')?$/, '') : __FILE__
  cur_path    = Pathname.new(first_path).dirname.realpath
  dot_base    = '.base'
  got_base    = lambda { cur_path.join(dot_base).exist? }
  cur_path    = cur_path.parent until cur_path == cur_path.parent or got_base[]
  ::BASE_PATH = got_base[] ? cur_path : raise("Can't find #{dot_base} for BASE_PATH")

  # read dot_base
  base_conf = IO.read(::BASE_PATH.join(dot_base)).strip.gsub(/[ \t]/, '').gsub(/\n+/, "\n")\
    .scan(/^\[(\w+)\]((?:\n[^\[].*)*)/)\
    .inject(Hash.new('')) { |h, (k, s)| h[k.to_sym] = s.strip; h }

  # set path consts
  consts    = base_conf[:consts].scan(/([A-Z][A-Z0-9_]*)=(.+)/).inject({}) { |h, (k, v)| h[k] = v; h }
  RX_CONSTS = /^(#{consts.keys.map(&Regexp.method(:escape)).join('|')})\//
  consts.each do |k, v|
    const_base = v.sub!(RX_CONSTS, '') ? Object.const_get($1) : ::BASE_PATH
    Object.const_set(k, const_base.join(v))
  end

  # set load_paths
  load_paths = base_conf[:load_paths].split("\n").map { |s| Dir[::BASE_PATH.join(s).to_s] }.flatten
  load_paths = load_paths.select { |s| File.directory? s }
  load_paths.each do |s|
    s.sub!(RX_CONSTS, '')
  end
  $LOAD_PATH.unshift(*load_paths)

  # requires
  loaded = caller(0).map { |s| s[/\A(.+?)(?:\.rb)?:\d+(?::in `.*?')?\z/, 1] }.compact.uniq
  base_conf[:requires].split("\n").each do |lib|
    rx = /\b#{Regexp.escape(lib)}\z/
    break if loaded.any? { |s| s =~ rx }
    require lib
  end
end.call
