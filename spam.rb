require "./event"
events = Event::Client.new :events
# c = Comment.new(content: Faker::Lorem.sentence)
# events.write("comment.create", c.to_h)
id = ARGV.shift
events.write('comment.flag_spam', {id: id})
