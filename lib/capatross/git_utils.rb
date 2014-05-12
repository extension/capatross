# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# Original (c) 2012 Jason Adam Young
# === LICENSE:
# see LICENSE file
require 'grit'

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
      if(@gitconfig.nil?)
        if(localrepo)
          @gitconfig = Grit::Config.new(localrepo)
        end
      end
      @gitconfig
    end

    def user_name
      if(@user_name.nil?)
        if(gitconfig)
          @user_name = gitconfig.fetch('user.name')
        end
      end
      @user_name
    end

    def user_email
      if(@user_email.nil?)
        if(gitconfig)
          @user_email = gitconfig.fetch('user.email')
        end
      end
      @user_email
    end

  end
end
