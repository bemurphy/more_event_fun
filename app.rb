require "securerandom"
require "json"
require "faker"
require "./event"

module Model
  def self.included(base)
    base.send(:attr_accessor, :id)
    base.send(:attr_accessor, :created_at)
  end

  def initialize(attrs = {})
    attrs.each do |k, v|
      m = "#{k}="
      send(m.to_sym, v)
    end
    self.id ||= SecureRandom.uuid
    self.created_at ||= Time.now.to_i
  end

  def as_json
    {id: id, created_at: created_at, type: self.class.name}
  end

  def to_h
    as_json
  end

  def to_json
    as_json.to_json
  end
end

class Comment
  include Model

  attr_accessor :content

  def as_json
    super.merge({
      content: content
    })
  end
end

events = Event::Client.new :events

100.times do
  c = Comment.new(content: Faker::Lorem.sentence)
  event_name = %w[comment.create comment.update].sample
  event_name = %w[comment.create].sample
  events.write(event_name, c.to_h)
end
