require 'rubygems'
require 'escape_utils'
require 'uri_template'

class Datapimp::GithubClient::Request

  MissingArguments = Class.new(Exception)

  attr_accessor :options, :user, :org, :repo, :params, :headers, :github_token

  class_attribute :_required_arguments

  def self.requires *args
    (self._required_arguments = args).uniq!
  end

  def self.required_arguments
    Array(self._required_arguments).uniq
  end

  def initialize(options={}, &block)
    @options = options.with_indifferent_access.dup
    @client, @user, @org, @repo, @github_token = options.values_at(:client, :user,:org,:repo,:github_token)
    @params   = options[:params] || {}
    @headers  = options[:headers] || {}

    instance_eval(&blk) if block_given?

    assert_valid_arguments!
  end

  def required_arguments
    Array(self.class._required_arguments)
  end

  def with_valid_arguments &blk
    instance_eval(&blk) if block_given?
    assert_valid_arguments!
    self
  end

  def assert_valid_arguments!
    return true if required_arguments.length > 0

    valid = required_arguments.all? do |arg|
      test = false
      test = true if !!self.send(arg).present?
      test = true if options.has_key?(arg)

      test
    end

    raise MissingArguments unless valid
  end

  def to_object
    req = self

    response_wrapper = lambda do |r|
      Datapimp::GithubClient::ResponseObject.new(r).with_request_object(req)
    end

    return object.map(&response_wrapper) if object.is_a?(Array)

    response_wrapper.call(object)
  end

  def object
    records
  end

  def all
    to_object
  end

  def create params={}
    client.post_request(request_endpoint, params).request.run
  end

  def update record_id, params={}
    client.update_request("#{ request_endpoint }/#{ record_id }", params).request.run
  end

  def destroy record_id, params={}
    client.delete_request("#{ request_endpoint }/#{ record_id }").request.run
  end

  def show record_id, params={}
    client.get_request("#{ request_endpoint }/#{ record_id }", params).to_object
  end

  def client
    return @client if @client

    if impersonate_user.present?
      @client = Datapimp::GithubClient::Client.new(user: impersonate_user, headers: headers, github_token: github_token)
    end

    @client = Datapimp.github_client
  end

  def records
    @records = request.records
  end

  def results
    records
  end

  def result
    records
  end

  def request_endpoint
    options.fetch(:endpoint, endpoint)
  end

  def request
    @request ||= client.get_request(request_endpoint, params)
  end

  def organization_or_user
    supplied_org.presence || user
  end

  def user_or_organization
    supplied_user || supplied_org
  end

  def org
    organization_or_user
  end

  # The idea of 'supplied' means it was provided to the object
  # and not calculated in any way.  This is used when determining
  # the value for the endpoint, in the context of a github user vs github organization
  def supplied_org
    @org
  end

  def supplied_user
    @user
  end

  def supplied_repo
    @repo
  end

  protected
    def github_token
      @github_token || impersonate_user.try(:github_token) || Datapimp.config.profile.github_token
    end

    def endpoint
      "users/#{ user }"
    end

    def impersonate_user
      if defined?(::User) && ::User.respond_to?(:find_by_github_nickname)
        @impersonate_user ||= ::User.find_by_github_nickname(user)
      end
    end
end
