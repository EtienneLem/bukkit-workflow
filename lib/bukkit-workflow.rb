require 'time'
require 'fileutils'

STORAGE_FOLDER = "#{ENV['HOME']}/.bukkit-workflow"
STORAGE_FILE = "#{STORAGE_FOLDER}/storage"
TIMESTAMP_FILE = "#{STORAGE_FOLDER}/timestamp"

STORAGE_TIME_IN_MINUTES = 10

def get_remote_images
  images = `curl bukk.it`.scan(/a href="(.+\.(jpg|gif))"/).map { |f| f[0] }
  store_images!(images)

  images
end

def get_cached_images
  File.read(STORAGE_FILE).split("\n")
end

def get_timestamp
  File.read(TIMESTAMP_FILE)
end

def create_storage_folder
  FileUtils.mkdir(STORAGE_FOLDER)
end

def store_images!(images)
  create_storage_folder unless File.directory?(STORAGE_FOLDER)

  File.open(STORAGE_FILE, 'w') do |file|
    file.write images.join("\n") + "\n"
  end

  File.open(TIMESTAMP_FILE, 'w') do |file|
    file.write Time.now
  end
end

def get_remote_images?
  begin
    last_fetch = Time.parse(get_timestamp)
    difference = (Time.now - last_fetch) / 60
    difference > STORAGE_TIME_IN_MINUTES ? true : false
  rescue
    true
  end
end

images = get_remote_images? ? get_remote_images : get_cached_images
filtered_images = images.grep(/{query}/i)

items = ''
filtered_images.each do |image|
  items << <<-ITEM
  <item uid="#{image.gsub(/-|\./, '_')}" arg="#{image}">
    <title>#{image}</title>
    <subtitle>Copy “http://bukk.it/#{image}” to clipboard</subtitle>
    <icon type="filetype">public.jpeg</icon>
  </item>
  ITEM
end

puts <<-XML
<?xml version="1.0"?>
<items>
  #{items}
</items>
XML
