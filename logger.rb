require "./event"
require "pp"

events = Event::Client.new(:events)
events.each do |data|
  pp data
end
