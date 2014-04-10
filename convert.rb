require 'trollop'
require 'fileutils'

opts = Trollop::options do
  opt :archive_url,   "The archive to convert to an RPM",               :type => :string
  opt :name,          "The name to use for the package",                :type => :string
  opt :package_version,       "The the version of the software being packages", :type => :integer
  opt :install_root,  "Where to install the software",                  :default => '/opt'
  opt :binary_root,   "Where to put symlinks for binaries",             :default => '/usr/local/bin'
  opt :binaries,      "Binaries to link",                               :type => :strings
end

def die_if_option_missing(opts,option)
  if opts[option].nil?
    abort "Please specify a #{option.to_s} for this package"
  end
end

die_if_option_missing(opts,:name)
die_if_option_missing(opts,:package_version)
die_if_option_missing(opts,:archive_url)

puts "here"

package_url     = opts[:archive_url]
version_number  = opts[:package_version]
name            = opts[:name]
binaries        = opts[:binaries]
install_root    = opts[:install_root]
bin_link_root   = opts[:binary_root]

puts "boo"

package_name = File.basename package_url
temp_root = 'temporary_root'

def make_directory(directory_to_make)
  puts "Making directory: #{directory_to_make}"
  FileUtils.mkdir(directory_to_make)
end

def clean_and_create_directory(directory)
  FileUtils.rm_rf directory if File.directory? directory
  make_directory directory
end

def download_file(target_file_name, source_url)
  puts "Downloading #{source_url} to #{target_file_name}"
  `curl -L #{source_url} -o #{target_file_name}` unless File.exists?(target_file_name)
end

def get_targz_root_directories(package_name)
  `tar tzf #{package_name} | sed -e 's@/.*@@' | uniq`.split("\n")
end

def only_one_root_directory?(archive_root_directories)
  archive_root_directories.count == 1
end

def run_command(command,description=nil)
  puts description unless description.nil?
  puts "Running command: #{command}"
  output = `#{command}`
  return_code = $?.to_i
  puts output
  if return_code != 0
    puts "Failed: #{description}"
    false
  end
  true
end

clean_and_create_directory(temp_root)
download_file(package_name, package_url)

archive_root_directories = get_targz_root_directories(package_name)
package_directory = archive_root_directories.first
temp_install_root = File.join(temp_root, install_root)

make_directory(temp_install_root)

run_command("tar -C #{temp_install_root} -xzf #{package_name}",'Unpacking the archive to the temp root')


if ! binaries.nil?
  binaries.each do |binary_location|
    binary_name = File.basename(binary_location)
    FileUtils.mkdir_p(File.join(temp_root,bin_link_root))
    link_command = "ln -s #{File.join(install_root,package_directory,binary_location)}  #{File.join(temp_root,bin_link_root,binary_name)}"
    run_command(link_command)
  end
end

fpm_build = "fpm -t rpm -s dir -f -n #{name} -v #{version_number} -C #{temp_root} ./"

run_command(fpm_build,'Building rpm with fpm')

FileUtils.rm_rf temp_root if File.directory? temp_root