# frozen_string_literal: true
class SvnParser
  # List IDs of collections that have been modified since a given date
  # @param [Date] date
  def updated_collection_codes(date)
    date = date.to_formatted_s(:iso8601)
    parse_collection_ids(exec("diff --summarize -r {#{date}}:HEAD #{svn_root}"))
  end

  # List the paths of all collections
  def all_collection_paths
    parse_collection_paths(exec("list --recursive #{svn_root}"))
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
      svn_output.split("\n").select { |s| s.end_with?(".EAD.xml") }
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
end
