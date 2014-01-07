require "./event"
events = Event::Client.new :events
id = ARGV.shift
events.write('comment.flag_spam', {id: id})
