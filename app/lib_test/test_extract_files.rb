# frozen_string_literal: true

require 'zip'

module Gingr
  # extracting files for Gingr
  class Extracter
    def unzip(zipfile_path, to_path)
      Zip::File.open(zipfile_path) do |zipfile|
        zipfile.each do |file|
          to_filepath = File.join(to_path, file.name)
          FileUtils.mkdir_p(File.dirname(to_filepath))
          zipfile.extract(file, to_filepath) { true }
        end
      end
    end
  end
end

ex = Gingr::Extracter.new
f = '/Users/zhouyu/Downloads/a.zip'
t = '/Users/zhouyu/Downloads/e'
ex.unzip(f, t)

# FileUtils.cp(src_path, filesystem_root)
