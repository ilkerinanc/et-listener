# encoding: UTF-8
class Listener
  @queue = :et_listen
  SOURCE_NAME = "Twitter"
  SOURCE_ID = 1

  def self.perform
    # Add a new stream job to stream_twitter_queue. When the job is failed, new job can start automaticly as early as possible
    Resque.enqueue(Listener)

    # # Create a follow list as string
    # prepare_list

    # return if @follow_ids_as_string == ''

    # Set initial value for count
    count = 0

    # Initialize the streamer
    @streamer = TweetStream::Client.new

    @streamer.on_inited do 
      puts "Connected...."
      # Set timers
      # set_timers
    end

    @streamer.track('#istanbul', '@emergentweet_tw') do |status|
      # puts "#{status.text}"
      puts status.text
      hashtags=status.hashtags.collect(&:text)
      if (hashtags.include?('ne') and hashtags.include?('nerede')) or (hashtags.include?('kim') and hashtags.include?('nerede'))
        Resque::Job.create("et_analyze", 'Analyzer', parse_tweet(status), 1)
      elsif (hashtags.include?('cozuldu') or hashtags.include?('cozulmedi')) and status.reply?
        Resque::Job.create("et_analyze", 'Analyzer', parse_tweet(status), 2)
      end
    end

  rescue Exception => message
    puts message
    sleep 10
  end

  private

  class << self

    def parse_tweet(entry)
      parsed_tweet = {
        "entry" => {
          "author_id" =>entry.user.id,
          "author_username" => entry.user.screen_name,
          "tid" => entry.id,
          "value" => entry.text,
          "in_reply_to_tid" => entry.in_reply_to_status_id.to_s,
          "permalink" => "http://www.twitter.com/#{entry.user.screen_name}/statuses/#{entry.id}",
          "posted_at" => entry.created_at.utc
        }
      }
      return parsed_tweet
    end
   
    # def prepare_follow_ids
    #   usernames = ids = Array.new
    #   Search.find_each(:batch_size => 150) do |search|
    #     unless search.data_hash["twitter_users"].nil?
    #      search.data_hash["twitter_users"].each{|u| usernames << u}
    #     end
    #   end
    #   ids = []
    #   usernames.uniq.each{|u| ids << Utilities.get_twitter_id_from_username(u)}
    #   return ids.reject(&:nil?).join(",")
    # end

    # def set_timers
    #   # Check time and if there is no tweet in 15 minutes, maybe connection lost. So, stop the streamer and reconnect.
    #   @timer = Thread.new do
    #     loop do
    #       sleep(20)
    #       if (Time.now-@last_tweet_time).to_i > (60*15)
    #         @streamer.stop
    #         puts "Send mail to us timer error"
    #         Thread.kill(Thread.current)
    #       end
    #     end
    #   end

    #   # After 12 hours kill connection and reconnect with new followers if there exist
    #   @timer2 = Thread.new do
    #     sleep(60*60*12)
    #     @streamer.stop
    #     puts "Send mail to us stream has forced to stop in order to update keywords"
    #     Thread.kill(Thread.current)
    #   end
    # end

    # def set_since_id since_id
    #   @since_id = since_id
    #   Utilities.set_since_id(@since_id)
    # end

    # def call_url_builder status_id
    #   puts "URLBuilder calling with parameters #{@since_id}, #{status_id}"
    #   Resque.enqueue(UrlBuilder, {"since_id" => @since_id, "last_id"=> status_id, "follow_user" => "true"})
    # end
  end

end