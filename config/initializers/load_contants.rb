## Caricamento delle costanti ##
CONFIG_FILES = ["constants"]

CONFIG_FILES.each do |file_name|
  tmp = YAML.load_file(File.join("#{Rails.root}","config","#{file_name}.yml")).symbolize_keys!
  eval("#{file_name.upcase} = tmp")
end