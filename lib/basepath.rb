require 'pathname'

lambda do
  return if Object.const_defined?("BASE_PATH")

  # find and set base
  first_path  = (s = caller.last) ? s.sub(/:\d+$/, '') : __FILE__
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
  base_conf[:consts].scan(/([A-Z][A-Z0-9_]*)=(.+)/).each { |k, v| Object.const_set(k, ::BASE_PATH.join(v)) }

  # set load_paths
  load_paths = base_conf[:load_paths].split("\n").map { |s| Dir[::BASE_PATH.join(s).to_s].select { |s| File.directory? s } }.flatten
  $LOAD_PATH.unshift(*load_paths)

  # requires
  loaded = caller(0).map { |s| s[/\A(.+?)(?:\.rb)?:\d+(?::in `.*?')?\z/, 1] }.compact.uniq
  libs   = base_conf[:requires].split("\n").each do |lib|
    rx = /\b#{Regexp.escape(lib)}\z/
    break if loaded.any? { |s| s =~ rx }
    require lib
  end
end.call
