#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'watir-webdriver'
require 'open-uri'
require 'nokogiri'

# 投稿するページの情報を取得
url = ARGV.shift
if !(url =~ /^http/)
  puts 'Usage Error'
  puts '  bundle exec ruby post_to_facebook.rb http://hostname/path/to/resource'
  exit 1
end
doc  = Nokogiri::HTML(open(url))
params = {}
[:title, :image, :description].each do |key|
  dom = doc.css("meta[property='og:#{key}']")[0]
  params[key] = dom.attributes['content'].value if dom && dom.attributes['content'] && dom.attributes['content'].value

  # ページ内容を出力
  case key
  when :title
    puts "タイトル:\n" + params[key]
  when :description
    puts "ページ詳細:\n" + params[key]
  end
end

# Facebook アカウント情報の取得
print 'メールアドレス: '
email = $stdin.gets.chop
print 'パスワード: '
system "stty -echo"
password = $stdin.gets.chop
system "stty echo"
puts "\n"

# ローカルに画像を保存
filepath = nil
expand_filepath = nil
if params[:image]
  image_url = params[:image]
  filepath = 'tmp/' + File.basename(image_url)
  open(filepath, 'wb') do |file|
    open(image_url) do |data|
      file.write(data.read)
    end
    expand_filepath = File.expand_path(filepath)
  end
end

browser = Watir::Browser.new(:ff)

# Facebook ログインページへ移動
browser.goto('http://www.facebook.com')
sleep 5 # HACK: Ajax による ロードが完了するまで待つ
if !(browser.title =~/Facebook/) || !(browser.title =~ /ログイン/)
  puts 'Facebook のログインページへの移動に失敗しました。'
  exit 1
end

# Facebook へ ログイン
browser.text_field(id: "email").set(email)
browser.text_field(id: "pass").set(password)
browser.button(value: "ログイン").click
sleep 5 # HACK: Ajax による ロードが完了するまで待つ
if (browser.title =~ /ログイン/)
  puts 'Facebook の認証に失敗しました。'
  exit 1
end

# 写真・動画 リンクをクリック
browser.link(text: "写真・動画").click
sleep 5 # HACK: Ajax による ロードが完了するまで待つ

# 写真・動画をアップロード リンクをクリック
browser.link(text: "写真・動画をアップロード").click
sleep 5 # HACK: Ajax による ロードが完了するまで待つ

browser.file_field(name: 'file1').set(expand_filepath)

exit 0
