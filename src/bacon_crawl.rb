require_relative "./queue"

require 'rest-client'
require "pry"
require "nokogiri"
require "pp"

class BaconCrawl

  def initialize(person)
    @root = visit('http://www.imdb.com/name/nm0000102/')
    @home = 'http://www.imdb.com'
    @q = Queue.new()
    @found = false
    @person = person

    @cache = {}

    # fill up initial queue
    add_movies_or_cast(@root, "KEVIN BACON")
  end

  def bacon_first_search()
    if @q.all.empty?
      return false
    end

    # next node who's children to visit
    parent = @q.dequeue
    @root = visit(parent[:node])

    if @found
      pretty_print(@found)
      return true
    else
      add_movies_or_cast(@root, parent)
      bacon_first_search()
    end

  end

  private

  def pretty_print(node)
    message = ""
    degrees = 0
    while node
      if node[:type] == 'movie'
        message += " WAS IN #{node[:content]} WITH "
        degrees += 1
      else
        message += "#{node[:content]}"
      end
      node[:parent] == 'KEVIN BACON' ? node = nil : node = node[:parent]
    end
    puts " #{degrees} degrees from KEVIN BACON!"
    puts message + " WITH KEVIN BACON"
  end

  def add_movies_or_cast(root, parent)
    !root.css("#filmography").empty? ? add_movies(root, parent) : add_cast_members(root, parent)
  end

  def add_movies(root, parent)
    elements = root.css(movie_query)
    2.times do
      movie = elements.shift
      if movie
        node = movie[:href]
        content = movie.content
        if @cache[content]
          next
        else
          @cache[content] = true
          add_to_queue(node, content, parent, "movie")
        end
      end
    end

  end

  def add_cast_members(root, parent)
    elements = root.css(cast_query)
    2.times do
      cast = elements.shift
      if cast.css('a').first
        node = cast.css('a').first[:href]
        content = cast.css('a').first.content

        if cast.css('a').first.content.include? @person
          @found = add_to_queue(node, content, parent, "cast")
        elsif cast.css('a').first.content.include? "Kevin Bacon"
          next
        elsif @cache[content]
          next
        else
          @cache[content] = true
          add_to_queue(node, content, parent, "cast")
        end
      end
    end

  end

  def add_to_queue(node, content, parent, type)
    newNode = {
      node: "#{@home}#{node}",
      content: content,
      type: type,
      parent: parent,
      }

    @q.enqueue(newNode)

    return newNode
  end

  def cast_query
    '#titleCast > table tr td.itemprop'
  end

  def movie_query
    '#filmography > div:nth-child(2) div b > a'
  end

  def next_node
    visit(@q.dequeue[:node])
  end

  def visit(url)
    puts url
    begin
      response = RestClient.get url
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end

    Nokogiri::HTML(response)
  end

end
