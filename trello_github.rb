# Read Trello cards and convert them to Github Issues
require "rest-client"
require "yaml"
require "json"


# Handles communication with the Trello API.
class Trello
  def initialize
    @api_root = "https://api.trello.com/1/"

    config = YAML.load(File.open("config.yml"))

    @key = config["trello"]["api_key"]
    @token = config["trello"]["user_token"]
  end

  # Given a card URL, return the card as JSON.
  def card_from_url(url)
    uri = URI.parse url
    card *uri.path.split("/")[-2..-1]
  end

  # Given the board id and card short id, return the card as JSON.
  def card(board_id, card_short_id)
    url = File.join(@api_root, "boards", board_id, "cards", card_short_id)
    data = RestClient.get url, {params: {key: @key, token: @token}}
    JSON.parse data
  end
end

# Handles communication with the Github API.
class Github
  attr_reader :login

  def initialize
    config = YAML.load(File.open("config.yml"))

    @login = config["github"]["login"] # username of issue creator
    @password = config["github"]["password"]
    @username = config["github"]["username"] # username of repo owner
    @repository = config["github"]["repository"]
    
    @api_root = "https://#{@login}:#{@password}@api.github.com/"
  end

  # Returns the data for the specified issue.
  def issue(issue_id)
    url = File.join(@api_root, "repos", @username, @repository, "issues", issue_id.to_s)
    data = RestClient.get url
    JSON.parse data
  end

  # Creates a new Github issue from the supplied hash, and returns the JSON
  # representation of the created issue. Possible issue_data: {title: String,
  # body: String, assignee: String, milestone: String, labels: Array}
  def create_issue(issue_data)
    url = File.join(@api_root, "repos", @username, @repository, "issues")
    result = RestClient.post url, issue_data.to_json, {
      content_type: :json, accept: :json
    }
    JSON.parse result
  end
end

# Handle command-line invocation
trello = Trello.new
github = Github.new

card_data = trello.card_from_url(ARGV[0])

issue_data = {
  title: card_data["name"],
  body: card_data["desc"]
}

issue = github.create_issue(issue_data)
puts "#{github.login} successfully created issue #{issue['html_url']}."
