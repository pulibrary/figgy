# frozen_string_literal: true
class SvnParser
  # List IDs of collections that have been modified since a given date
  # @param [Date] date
  def updated_collection_codes(date)
    parse_collection_ids(updated_since(date))
  end

  # List paths of collections that have been modified since a given date
  # The output is suitable for retrieving the collections using `get_collection`.
  # @param [Date] date
  def updated_collection_paths(date)
    parse_collection_paths(updated_since(date))
  end

  # Get the EAD XML for a collection
  def get_collection(path)
    exec("cat #{svn_root}/#{path}")
  end

  private

    def exec(svn_cmd)
      stdout, status = Open3.capture2("svn #{svn_auth} #{svn_cmd}")
      raise StandardError unless status.success?
      stdout
    end

    def parse_collection_ids(svn_output)
      svn_output.split("\n").map do |line|
        line.rpartition("/").last.partition(".").first
      end
    end

    def parse_collection_paths(svn_output)
      svn_output.split("\n").map do |line|
        line.gsub(/.*#{svn_root}\//, "")
      end
    end

    def svn_auth
      "--username #{svn_config['user']} --password #{svn_config['pass']}"
    end

    def svn_config
      @svn_config ||= Rails.application.config_for :svn
    end

    def svn_root
      File.join(svn_config["url"], "pulfa/trunk/eads")
    end

    def updated_since(date)
      date = date.to_formatted_s(:iso8601) if date.is_a?(Date)
      exec("diff --summarize -r {#{date}}:HEAD #{svn_root}")
    end
end
