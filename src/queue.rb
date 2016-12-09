class Queue

  attr_reader :all

  def initialize
    @all = []
  end

  def enqueue(node)
    @all.push(node)
  end

  def dequeue
    @all.shift
  end

  def prioritize(node)
    @all.unshift(node)
  end

end
