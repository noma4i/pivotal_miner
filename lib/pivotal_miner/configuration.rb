module PivotalMiner
  class Configuration

    def initialize
      load_configuration
    end

    def pivotal_miner
      @pivotal_miner ||= File.join(Rails.root, 'config', 'pivotal_miner.yml')
    end

    def map_config
      config['mappings']
    end

    def load_configuration
      unless File.exist?(pivotal_miner)
        raise MissingPivotalMinerConfig, 'Missing pivotal_miner.yml configuration file in /config'
      end
      self.config = YAML.load_file(pivotal_miner)
    end

    def error_notification
      # config['error_notification']
    end

    def credentials(user)
      PivotalMiner::Credentials.new(user, config)
    end

    private

    attr_accessor :config
  end
end
