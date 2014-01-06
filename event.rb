# require "redis"
require "json"
require "bunny"

module Event
  class Client
    def initialize(topic_name)
      @topic_name = topic_name.to_s
      @bunny = Bunny.new
      @bunny.start
      @channel  = @bunny.create_channel
      @exchange = @channel.topic(@topic_name, auto_delete: true)
    end

    def write(event_name, properties)
      payload = {
        event_name: event_name,
        properties: properties
      }

      @exchange.publish(payload.to_json, routing_key: event_name)
    end

    def on(queue_name, key, &block)
      puts "binding on key #{key}"
      @channel.queue(queue_name).bind(@exchange, routing_key: key).subscribe do |_, _, payload|
        block.call JSON[payload]
      end
    end
  end

  class HandlerCollection
    def initialize(topic_name)
      @events = Event::Client.new(topic_name)
      # @writer = Event::Client.new(channel_name)

      @handlers = Hash.new do |h, k|
        h[k] = []
      end
    end

    def register(queue_name, *event_names, &block)
      Array(event_names).each do |key|
        @events.on(queue_name, key) do |data|
          block.call Hashie::Mash.new(data["properties"])
        end
      end
    end

    def process(data)
      unhandled = true

      props = Hashie::Mash.new(data["properties"])
      handlers = @handlers[data["event_name"].to_s]
      handlers.each do |handler|
        unhandled = false
        handler.call props
      end

      if unhandled
        # @writer.write("unhandled", data)
      end
    end

    def start
      sleep 300
    end
  end

  module Handler
    def self.included(base)
      base.extend ClassMethods
    end

    def events
      self.class.events
    end

    module ClassMethods
      def events
        @@events ||= Event::HandlerCollection.new(:events)
      end

      def handler_subscriptions
        @handler_subscriptions ||= []
      end

      def subscribe(event_name, method_name)
        handler_subscriptions << [event_name, method_name]
      end

      def start
        handler_subscriptions.each do |event_name, method_name|
          queue_name = [name, method_name].join("#")
          events.register queue_name, event_name do |o|
            new.send method_name.to_sym, o
          end
        end
      end
    end
  end
end
