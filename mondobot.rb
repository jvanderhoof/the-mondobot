class Mondobot < Sinatra::Base
  post '/heroku' do
    log(params)
  end

  get '/testing' do
    "testing: 1,2,3....."
  end

  private
  def log(msg)
    @log ||= Logger.new(STDOUT)
    @log.error(msg)
  end
end
