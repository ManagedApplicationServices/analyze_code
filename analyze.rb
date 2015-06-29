PATH = "~/Working/scheduler"

def fileSize(directory)
  return 0 if directory.path.split('/')[-1].start_with?('.')
  return directory.size unless File.directory?(directory)

  Dir.entries(directory)[2..-1].inject(0) do |result, sub_dir|
    result + fileSize(directory_of_path(directory.path + '/' + sub_dir))
  end
end

def directory_of_path(dir)
  File.open(File.expand_path(dir))
end

def file_size_format(size)
  file_in_MB = size / (1024**2)
  file_in_MB < 1024 ?  "Size is %4d MB" % file_in_MB : "Size is %.2f GB" % (file_in_MB.to_f / 1024)

end

p file_size_format(fileSize(directory_of_path(PATH)))

