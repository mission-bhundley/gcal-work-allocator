require "google/apis/calendar_v3"
require "googleauth"
require "googleauth/stores/file_token_store"
require "date"
require "fileutils"

APPLICATION_NAME = 'Google Calendar Work Allocator'
CREDENTIALS_PATH = "config/credentials.json".freeze
OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "config/token.yaml".freeze
SCOPE = [
  Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY,
  Google::Apis::CalendarV3::AUTH_CALENDAR_EVENTS
]


require 'ruby-limiter'

class RateLimitedService < Google::Apis::CalendarV3::CalendarService
  extend Limiter::Mixin

  # 5 reqs / sec
  limit_method :insert_event, rate: 5, interval: 1
  limit_method :delete_event, rate: 5, interval: 1
end


##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

def new_google_calendar_client
  # Initialize the API
  RateLimitedService.new.tap do |service|
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
  end
end
