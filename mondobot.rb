class App < Sinatra::Base
  post '/heroku' do

  end

  private
  def log(msg)
    @log ||= Logger.new(STDOUT)
    @log.error(msg)
  end
end
