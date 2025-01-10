#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'yaml'

##
# ブログ記事から発表者名に基づいてタグを付けるスクリプト。
# - 指定したURLの一覧をScrapingし、記事本文を取得する。
# - 事前に用意した発表者名のリストを参照し、本文に含まれている発表者名をタグとして付与する。
#
# 使用例:
#   ruby tag_rubykaigi_blog.rb

speakers = URI.open('https://raw.githubusercontent.com/ruby-no-kai/rubykaigi-static/refs/heads/master/2024/data/speakers.yml') do |f|
  YAML.safe_load(f)
end

presentations = URI.open('https://raw.githubusercontent.com/ruby-no-kai/rubykaigi-static/refs/heads/master/2024/data/presentations.yml') do |f|
  YAML.safe_load(f)
end

def download_blogs
end

def download_file(uri, path)
  URI.open(uri) do |response|
    IO.copy_stream(response, "#{path}/#{filename}")
  end
end

def fetch_blog_text(url)
  html = URI.open(url) do |f|
    f.read
  end

  doc = Nokogiri::HTML(html)

  article_element = doc.at_css('article')
  return '' unless article_element

  article_element.text
end


def extract_presenter_tags(text, presenters)
  tags = []

  presenters.each do |presenter|
    id = presenter.first
    name = find_name_in_keynotes_or_speakers(presenters, id)
    title = presenter.last['title']

    regexp = Regexp.new("#{id}|#{name}|#{title}", Regexp::IGNORECASE)
    tags << name if text.match?(regexp)
  end
  tags
end

def find_name_in_keynotes_or_speakers(data, target_id)
  %w[keynotes speakers].each do |top_key|
    next unless data[top_key]

    data[top_key].values.each do |person_hash|
      return person_hash["name"] if person_hash["id"] == target_id
    end
  end

  nil
end

def main
  BLOG_URLS.each do |url|
    body_text = fetch_blog_text(url)
    tags = extract_presenter_tags(body_text, presentations)

    puts "URL: #{url}"
    puts "Tags: #{tags.join(', ')}"
    puts "-----"
  end
end

main
