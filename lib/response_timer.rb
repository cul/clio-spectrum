
# http://asciicasts.com/episodes/151-rack-middleware

class ResponseTimer

  def initialize(app, message = "Response Time")
    @app = app
    @message = message
  end

  def call(env)
    @start = Time.now
    @status, @headers, @response = @app.call(env)
    @stop = Time.now
    @elapsed = (@stop - @start) * 1000
    [@status, @headers, self]
  end

  def each(&block)
    if @headers and @headers["Content-Type"] and @headers["Content-Type"].include? "text/html"
      block.call("<!-- #{@message}: #{@elapsed.round(0)} ms -->\n")
    end

    @response.each(&block)
  end

end