module PivotalMiner
  module Authentication
    class << self

      def set_token(email)
        credentials = PivotalMiner::Configuration.new.credentials('super_user') ||
            raise(MissingCredentials, "Missing token for super_user in pivotal_miner.yml")

        set_token_from_config(credentials)
        PivotalTracker::Client.use_ssl = true
      rescue => e
        raise WrongCredentials.new("Wrong Pivotal Tracker credentials in PivotalMiner.yml. #{e}")
      end

      def set_token_from_config(credentials)
        @token = credentials.token
        PivotalTracker::Client.token = @token
      end
    end
  end
end