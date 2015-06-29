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

def most_modifier
  output = %x( cd #{PATH} && git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -20)
  shell_output(output).each do |item|
    p item
  end
end

def shell_output(output)
  output.split("\n  ")[1..-1]
end

def model_stats
  directory = directory_of_path(PATH + "/app/models")

  result = []
  Dir.entries(directory)[2..-1].each do |sub_dir|
    path = directory_of_path(directory.path + '/' + sub_dir)
    next if File.directory?(File.open(path))
    data = File.open(path).read

    result << (
      {
        file_name: sub_dir,
        has_many: data.scan(/has_many/i).count,
        has_one: data.scan(/has_many/i).count,
        belongs_to: data.scan(/belongs_to/).count
      }
    )
  end

  result
end

puts "="*30
puts "\tProject size"

p file_size_format(fileSize(directory_of_path(PATH)))

puts "="*30
puts "\tTop 20 modifiered files"
most_modifier

puts "="*30

printf "%-30s%-10s%-10s%-10s\n", "File Name", "Has Many", "Has One", "Belongs To"
model_stats.each do |model|
  printf "%-30s%-10s%-10s%-10s\n", model[:file_name], model[:has_many], model[:has_one], model[:belongs_to]
end
