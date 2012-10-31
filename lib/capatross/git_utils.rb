# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# Original (c) 2012 Jason Adam Young
# === LICENSE:
# see LICENSE file

module Capatross
  class GitUtils

    def initialize(path)
      @path = path
      if(localrepo)
        return self
      else
        return nil
      end
    end

    def localrepo
      if(@localrepo.nil?)
        begin
          @localrepo = Grit::Repo.new(@path)
        rescue Grit::InvalidGitRepositoryError
        end
      end
      @localrepo
    end

    def gitconfig
      @gitconfig ||= Grit::Config.new(localrepo)
    end

    def user_name
      @user_name ||= gitconfig.fetch('user.name')
    end

    def user_email
      @user_email ||= gitconfig.fetch('user.email')
    end

  end
end




