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
    def commit(group)
      svn_exec("commit -m \"Figgy DAO links for #{group.titleize}\"")
    end

    # create a branch and switch to it
    def create_branch(group)
      branch = "#{svn_url}/branches/#{group}-#{today}"
      svn_exec("copy #{svn_url}/trunk #{branch} -m \"#{group.titleize} review #{today}\"")
      svn_exec("sw #{branch}")
      branch
    end

    # switch to a branch
    def switch(basename)
      svn_exec("sw #{svn_url}/#{basename}")
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

      def svn_url
        @svn_url ||= File.join(svn_config["url"], "pulfa")
      end

      # execute a SVN command
      def svn_exec(cmd)
        logger.info "SVN: #{cmd}"
        system("cd #{svn_dir} && svn --username #{svn_config['user']} --password #{svn_config['pass']} #{cmd}") unless dry_run
      end

      # today's date, used for timestamping new branches
      def today
        Time.zone.today.strftime("%Y-%m-%d")
      end
  end
end
