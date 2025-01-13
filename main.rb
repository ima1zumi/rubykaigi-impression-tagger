# frozen_string_literal: true

require 'open-uri'
require 'yaml'

##
# ブログ記事から発表者名に基づいてタグを付けるスクリプト。
# - 指定したURLの一覧をScrapingし、記事本文を取得する。
# - 事前に用意した発表者名のリストを参照し、本文に含まれている発表者名をタグとして付与する。
# - articles/YEAR/urls.yaml にURLのリストを記述することで、対象の記事を指定する。
#
# 使用例:
#   ruby main.rb 2024

SPEAKERS = URI.open('https://raw.githubusercontent.com/ruby-no-kai/rubykaigi-static/refs/heads/master/2024/data/speakers.yml') do |f|
  YAML.safe_load(f)
end

PRESENTATIONS = URI.open('https://raw.githubusercontent.com/ruby-no-kai/rubykaigi-static/refs/heads/master/2024/data/presentations.yml') do |f|
  YAML.safe_load(f)
end

YEAR = ARGV[0]

def download_blogs
  unless File.exist?("articles/#{YEAR}/urls.yaml")
    puts "articles/#{YEAR}/urls.yaml not found."
    exit 1
  end

  File.open("articles/#{YEAR}/urls.yaml", 'r') do |f|
    urls = YAML.safe_load(f)
    urls.each do |url|
      download_file(url, "articles/#{YEAR}")
    end
  end
end

def safe_filename_from_url(url_str)
  url_str.gsub(/[^0-9A-Za-z._\-]/, '_')
end

def download_file(uri, path)
  safe_uri = safe_filename_from_url(uri)
  return if File.exist?("#{path}/#{safe_uri}")

  URI.open(uri) do |response|
    IO.copy_stream(response, "#{path}/#{safe_uri}")
  end
end

def fetch_blog_text(url)
  html = File.open("articles/#{YEAR}/#{safe_filename_from_url(url)}") do |f|
    f.read
  end

  html
end

def extract_presenter_tags(text, presenters)
  tags = []

  presenters.each do |presenter|
    id = presenter.first
    name = find_name_in_keynotes_or_speakers(SPEAKERS, id)
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
  if ARGV.empty?
    puts 'Please specify the year as an argument.'
    puts 'Usage: ruby main.rb 2024'
    exit 1
  end

  download_blogs

  File.open("articles/#{YEAR}/urls.yaml", 'r') do |f|
    urls = YAML.safe_load(f)
    urls.each do |url|
      body_text = fetch_blog_text(url)
      tags = extract_presenter_tags(body_text, PRESENTATIONS)

      puts "URL: #{url}"
      puts "Tags: #{tags.join(', ')}"
      puts "-----"
    end
  end
end

main
