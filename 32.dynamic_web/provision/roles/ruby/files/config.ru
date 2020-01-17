require 'sinatra'

get '/' do
    'Hello Otus from Ruby!'
end

run Sinatra::Application
