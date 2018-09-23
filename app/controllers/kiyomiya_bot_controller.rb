class KiyomiyaBotController < ApplicationController
  require 'line/bot'
  require 'mechanize'

  protect_from_forgery :except => [:first]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def first
      body = request.body.read
      signature = request.env['HTTP_X_LINE_SIGNATURE']
      unless client.validate_signature(body, signature)
        error 400 do 'Bad Request' end
  end

  def get_record #Yahooのサイトから清宮幸太郎のデータを取得して呼び出し元に返す
    agent = Mechanize.new
    page = agent.get("https://baseball.yahoo.co.jp/npb/player/1700025/")
    average = page.search('.yjM').children[1].inner_text #打率の取得
    homerun = page.search('.yjM').children[8].inner_text #本塁打数の取得
    rbi = page.search('.yjM').children[8].inner_text #本塁打数の取得
    records = {average: average, homerun: homerun, rbi: rbi}
    return records
  end


    text_params = params["events"][0]["message"]["text"] #メッセージイベントからテキストの取得


    events = client.parse_events_from(body)
    events.each { |event|
      case event
        when Line::Bot::Event::Message
          case event.type
            when Line::Bot::Event::MessageType::Text
               if text_params == "打点" then
                   message = {
                        type: 'text',
                        text: "#{get_record[:rbi]}打点です。"
                      }
                      client.reply_message(event['replyToken'], message)

              elsif text_params  == "打率" then
                      message = {
                        type: 'text',
                        text: "#{get_record[:average]}です。"
                      }
                      client.reply_message(event['replyToken'], message)

              elsif text_params == "本塁打" then
                      message = {
                        type: 'text',
                        text: "#{get_record[:homerun]}本塁打です。"
                      }
                      client.reply_message(event['replyToken'], message)

              else
                message = {
                  type: 'text',
                  text: "「打率」、「打点」、「本塁打」のどれかを入力してください。"
                }
                client.reply_message(event['replyToken'], message)
              end
          end
      end
      }
      head :ok
  end
end
