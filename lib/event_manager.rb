require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'pry-byebug'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def remove_punctuation(string)
  string.gsub(/[\D]/, '')
end

def clean_phone(phone)
  phone = remove_punctuation(phone)
  if phone.length < 10
    phone = 'N/A'
  elsif phone.length == 11 && phone[0] == 1
    phone[1..11]
  elsif phone.length == 11 && phone[0] != 1
    phone = 'N/A'
  elsif phone.length > 11
    phone = 'N/A'
  else
    phone
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def convert_time_to_hour(time)
  time_obj = convert_string_to_time(time)
  hour = time_obj.hour
end

def convert_time_to_day(time)
  time = convert_string_to_time(time)
  time.strftime("%A")
end

def convert_string_to_time(string)
  time_str = string.split
  date_str = time_str.first.split('/')
  year = date_str[-1]
  month = date_str[0]
  day = date_str[1]
  hour = time_str.last.split(':').first
  Time.new(year, month, day, hour)
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


time_hash = Hash.new(1)
time = ''

day_hash = {}
day = ''

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = clean_phone(row[:homephone])
  hour = convert_time_to_hour(row[:regdate])
  day = convert_time_to_day(row[:regdate])

  if time_hash.include? hour
    time_hash[hour] += 1
  else
    time_hash[hour] = 1
  end
  max = 0
  time_hash.each do |key, value|
    if value > max
      max = value
      time = key
    end
  end

  if day_hash.include? day
    day_hash[day] += 1
  else
    day_hash[day] = 1
  end
  max = 0
  day_hash.each do |key, value|
    if value > max
      max = value
      day = key
    end
  end

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  # puts "#{name} #{phone} #{zipcode}"
  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
  
end
puts "Peak hour is #{time}"
puts "Peak day is #{day}"
