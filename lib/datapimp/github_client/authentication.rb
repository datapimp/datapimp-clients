module Datapimp::GithubClient
  class Authentication
    attr_accessor :github_token, :options

    InvalidAuth = Class.new(Exception)

    def initialize(options={})
      options.symbolize_keys! if options.is_a?(Hash)
      @options = options
      fetch_token
    end

    protected

    def fetch_token
      @github_token = case
      when options.respond_to?(:github_token)
        options.github_token
      when options.is_a?(Hash) && options.has_key?(:github_token)
        options[:github_token]
      when options.is_a?(Hash) && (options.has_key?(:username) && options.has_key?(:password))
        fetch_token options.values_at(:username,:password)
      when "#{ENV['GITHUB_TOKEN']}".length > 1
        ENV['GITHUB_TOKEN']
      else
        raise InvalidAuth
      end

    end
  end
end
