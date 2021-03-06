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
    puts item
  end
end

def shell_output(output)
  output.split("\n  ")[1..-1]
end

def lines(file)
  %x( wc -l #{file.path} ).strip.split(' ').first
end

#FIXME: need to refactor so can use for controller also ^_^
def stats(type = "models")
  directory = directory_of_path(PATH + "/app/" + type)
  sub_dir_stat(directory)
end

def sub_dir_stat(directory)
  result = []

  Dir.entries(directory)[2..-1].each do |sub_dir|
    path = directory_of_path(directory.path + '/' + sub_dir)

    if File.directory?(directory_of_path(path))
      result.concat(sub_dir_stat(path))
      next
    end

    data = File.open(path).read

    result << (
      {
        file_name: sub_dir,
        lines: lines(path),
        methods_count: methods_count(data)
      }.merge(model_stat(data))
    )
  end

  result
end

def model_stat(data)
  {
    has_many: data.scan(/has_many/i).count,
    has_one: data.scan(/has_many/i).count,
    belongs_to: data.scan(/belongs_to/).count,
  }
end

def methods_count(data)
  data.scan(/def\s+.+/).count
end

def output_stat(name = 'data1', field = :lines)
  output = "#{name}=\'["

  datas = []
  stats.sort_by {|stat| -stat[:lines].to_i}.each do |model|
    color = "%06x" % (rand * 0xffffff)
    datas << "{\"%s\":\"%s\", \"%s\":\"%d\", \"%s\":\"#%s\"}" % [ "label", model[:file_name], "value", model[field], "color", color ]
  end

  output << datas.join(",")
  output << "]';"

  output
end

def export_to_json(output)
  File.open("output/data.json", "a+") do |file|
    file.write(output)
  end
end

export_to_json(output_stat('data1', :lines))
export_to_json(output_stat('data2', :methods_count))

puts "="*30
puts "\tProject size"

p file_size_format(fileSize(directory_of_path(PATH)))

puts "="*30
puts "\tTop 20 modifiered files"
most_modifier

puts "="*30

printf "%-30s%-10s%-10s%-10s%-10s%-10s%-10s\n", "File Name", "Has Many", "Has One", "Belongs", "Lines", "Methods Count", "Lines/methods"
stats.sort_by {|stat| -stat[:lines].to_i}.each do |model|
  printf "%-30s%-10s%-10s%-10s%-10s%-10s%-10.2f\n", model[:file_name], model[:has_many], model[:has_one], model[:belongs_to], model[:lines], model[:methods_count], model[:lines].to_f / model[:methods_count]
end

lines = stats.inject(0) { |result, item| result + item[:lines].to_i }
methods = stats.inject(0) { |result, item| result + item[:methods_count].to_i }

printf "Avg lines/method is: %5.2f. Avg lines/model %5.2f", methods / stats.count, lines / stats.count
