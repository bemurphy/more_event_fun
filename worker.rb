require "elasticsearch"
require "date"
require "./event"

def define_handler(class_name, &block)
  handler_class = Object.const_set(class_name.to_s, Class.new)
  handler_class.send :include, Event::Handler
  handler_class.class_eval &block
  handler_class.start
end

define_handler :SegmentIOHandler do
  subscribe "comment.create", :segment

  def segment(o)
    puts "Would notifiy segment.io here with #{o}"
  end
end

class CommentIndexHandler
  include Event::Handler

  subscribe "comment.flag_spam", :spam
  subscribe "comment.create", :insert_search_index
  subscribe "comment.unspam", :unspam

  def search
    @search ||= Elasticsearch::Client.new log: false
  end

  def spam(o)
    puts "Updating Comment #{o.id} as spam"
    search.update(index: 'myindex', type: 'Comment', id: o.id,
                  body: { doc: { spam: true } })
  end

  def unspam(o)
    puts "Updating Comment #{o.id} as ham"
    search.update(index: 'myindex', type: 'Comment', id: o.id,
                  body: { doc: { spam: false } })
  end

  def insert_search_index(o)
    puts "Index #{o.type}##{o.id}"

    search.index({
      index: 'myindex',
      type: o.type,
      id: o.id,
      timestamp: Time.now.iso8601,
      body: {
        content: o.content
      }
    })
  end
end

CommentIndexHandler.start
sleep 86_400
