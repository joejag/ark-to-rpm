require 'ark_to_rpm/version'
require 'fileutils'

module ArkToRpm
  class Converter

    def initialize(opts)
      abort_if_option_missing(opts, :name)
      abort_if_option_missing(opts, :package_version)
      abort_if_option_missing(opts, :archive_url)
      abort_if_option_missing(opts, :release)

      @package_url = opts[:archive_url]
      @version_number = opts[:package_version]
      @release = opts[:release]
      @name = opts[:name]
      @binaries = opts[:binaries]
      @install_root = opts[:install_root]
      @bin_link_root = opts[:binary_root]
      @package_name = File.basename @package_url
      @temp_root = 'temporary_root'
    end

    def convert
      clean_and_create_directory(@temp_root)
      download_file(@package_name, @package_url)

      archive_root_directories = get_archive_root_directories(@package_name)

      package_directory = archive_root_directories.first
      temp_install_root = File.join(@temp_root, @install_root)

      make_directory(temp_install_root)

      unpack_archive(temp_install_root,@package_name)

      setup_bin_symlinks(package_directory)

      fpm_build = "fpm -t rpm -s dir --force --name #{@name} --version #{@version_number} --iteration #{@release} -C #{@temp_root} ./"

      run_command(fpm_build, 'Building rpm with fpm')

      FileUtils.rm_rf @temp_root if File.directory? @temp_root

      FileUtils.rm_rf @package_name
    end

    def unpack_archive(temp_install_root,package_name)
      if is_tar_gz?(package_name)
        untar_gz_package(package_name, temp_install_root)
      end
      if is_zip?(package_name)
        unzip_package(package_name,temp_install_root)
      end
      if is_tar_bz2?(package_name)
        untar_bz2_package(package_name,temp_install_root)
      end
    end


    def is_zip?(package_name)
      package_name.end_with?('.zip')
    end

    def is_tar_gz?(package_name)
      package_name.end_with?('.tar.gz') || package_name.end_with?('.tgz')
    end

    def is_tar_bz2?(package_name)
      package_name.end_with?('.tar.bz2') || package_name.end_with?('.tbz')
    end

    def unzip_package(package_name, temp_install_root)
      run_command("unzip -d #{temp_install_root} #{package_name}", 'Unpacking the archive to the temp root')
    end

    def untar_gz_package(package_name, temp_install_root)
      run_command("tar -C #{temp_install_root} -xzf #{package_name}", 'Unpacking the archive to the temp root')
    end

    def untar_bz2_package(package_name, temp_install_root)
      run_command("tar -C #{temp_install_root} -xjf #{package_name}", 'Unpacking the archive to the temp root')
    end

    private
    def setup_bin_symlinks(package_directory)
      unless @binaries.nil?
        @binaries.each do |binary_relative_path|

          binary_name = File.basename(binary_relative_path)

          temp_bin_link_root = File.join(@temp_root, @bin_link_root)
          temp_bin_link_path = File.join(temp_bin_link_root, binary_name)
          original_binary_path = File.join(@install_root, package_directory, binary_relative_path)

          make_directory(temp_bin_link_root)

          link_command = "ln -s #{original_binary_path}  #{temp_bin_link_path}"
          run_command(link_command)
        end
      end
    end

    def abort_if_option_missing(options, option_to_check_for)
      if options[option_to_check_for].nil?
        abort "Please specify a #{option_to_check_for.to_s} for this package. Use -h for help."
      end
    end

    def make_directory(directory_to_make)
      puts "Making directory: #{directory_to_make}"
      FileUtils.mkdir_p(directory_to_make)
    end

    def clean_and_create_directory(directory)
      FileUtils.rm_rf directory if File.directory? directory
      make_directory directory
    end

    def download_file(target_file_name, source_url)
      puts "Downloading #{source_url} to #{target_file_name}"
      `curl -L #{source_url} -o #{target_file_name}` unless File.exists?(target_file_name)
    end

    def get_archive_root_directories(package_name)
      if is_tar_gz?(package_name)
        return get_archive_root_directories_for_tar_gz(package_name)
      end
      if is_zip?(package_name)
        return get_archive_root_directories_for_zip(package_name)
      end
      if is_tar_bz2?(package_name)
        return get_archive_root_directories_for_tar_bz2(package_name)
      end
    end

    def get_archive_root_directories_for_tar_bz2(package_name)
      `tar tjf #{package_name} | sed -e 's@/.*@@' | uniq`.split("\n")
    end

    def get_archive_root_directories_for_zip(package_name)
      `unzip -l #{package_name} | awk '{print $4}'| grep -v "^Name$" | grep -v "^----$" | grep -v "^$" | sed -e 's@/.*@@' | uniq`.split("\n")
    end

    def get_archive_root_directories_for_tar_gz(package_name)
      `tar tzf #{package_name} | sed -e 's@/.*@@' | uniq`.split("\n")
    end

    def only_one_root_directory?(archive_root_directories)
      archive_root_directories.count == 1
    end

    def run_command(command, description=nil)
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
  end
end
