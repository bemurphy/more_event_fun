require "./event"
events = Event::Client.new :events
id = ARGV.shift
events.write('comment.unspam', {id: id})
