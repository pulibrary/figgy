# frozen_string_literal: true
# Subversion client for interacting with local copy of PULFA SVN repository
class PulfaExporter
  class SvnClient
    class SvnDirectoryError < StandardError; end

    attr_reader :dry_run, :logger
    def initialize(dry_run: false, logger: Logger.new(STDOUT))
      @dry_run = dry_run
      @logger = logger
      raise SvnDirectoryError, "Not a directory: #{svn_dir}" unless File.directory?(svn_dir)
    end

    # commit local changes to the SVN server
    def commit
      svn_exec('commit -m "Figgy DAO links"')
    end

    # fetch changes from the SVN server
    def update
      svn_exec("update")
    end

    # base of pulfa svn directory
    # Note: public for clients to find and interact with files on disk
    def svn_dir
      @svn_dir ||= File.join(svn_config["dir"], "pulfa")
    end

    private

      def svn_config
        @svn_config ||= Rails.application.config_for :svn
      end

      # execute a SVN command
      def svn_exec(cmd)
        logger.info "SVN: #{cmd}"
        system("cd #{svn_dir} && svn --username #{svn_config['user']} --password #{svn_config['pass']} #{cmd}") unless dry_run
      end
  end
end
