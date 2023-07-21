require "honeybadger-api"
require "pry"
require "csv"
require 'time'

DATA_DIR = File.expand_path("../../data", __FILE__)
CSV_COLUMN_HEADERS = %w[fault_id notice_id notice_url error_class error_message notices_count notice_created_at notice_context notice_params]

def notice_paginator(fault_id)
  Honeybadger::Api::Notice.paginate(
    @project.id,
    fault_id,
    {
      created_after: @occurred_after,
      created_before: @occurred_before
    }
  )
end

def row(fault, notice)
  notice_created_at_local_tz = (notice.created_at + @offset.to_f/2400).new_offset(@offset).strftime("%F %T %Z")
  {
    :fault_id => fault.id,
    :notice_id => notice.id,
    :notice_url => notice.url,
    :error_class => fault.klass,
    :error_message => fault.message,
    :notices_count => fault.notices_count,
    :notice_created_at => notice_created_at_local_tz,
    :notice_context => notice.request[:context],
    :notice_params => notice.request[:params],
  }
end

Honeybadger::Api.configure do |c|
  c.access_token = ENV.fetch("HONEYBADGER_PRODUCTION_AUTH_TOKEN", "Please specify a honeybadger authentication token.")
end
# TODO check for PDT on nylas investigation
project_id = ARGV[0]
@error_class = ARGV[1]
occurred_after_str = Date.parse(ARGV[2])
@occurred_after = occurred_after_str.to_time.to_i
occurred_before_str = Date.parse(ARGV[3])
@occurred_before = occurred_before_str.to_time.to_i
@offset = Time.now.strftime("%z")

@project = Honeybadger::Api::Project.find(project_id)
csv_path = File.join(DATA_DIR, "#{@project.name}-notices-#{@error_class}-#{occurred_after_str}-#{occurred_before_str}.csv")
# json_path = File.join(DATA_DIR, "#{@project.name}-notices-#{@error_class}-#{occurred_after_str}-#{occurred_before_str}.json")
# json_arr = []

# get Faults
fault_paginator = Honeybadger::Api::Fault.paginate(
  @project.id,
  {
    q: "class:#{@error_class}",
    occurred_after: @occurred_after,
    occurred_before: @occurred_before,
    order: "frequent"
  }
)
fault_pages = fault_paginator.pages.values

CSV.open(csv_path, "w") do |csv|
  csv << CSV_COLUMN_HEADERS

  fault_pages.each do |fault_page|
    while fault_page&.any?
      fault_page.each do |fault|
        # get Notices per Fault
        notice_paginator = notice_paginator(fault.id)
        notice_pages = notice_paginator.pages.values

        notice_pages.each do |notice_page|
          while notice_page&.any?
            notice_page.each do |notice|
              csv << row(fault, notice).values
              # json_arr << item
            end
          notice_page = notice_paginator.next
        end
      end
    end
      fault_page = fault_paginator.next
    end
  end
end

# File.write(json_path, JSON.pretty_generate(json_arr))
p "Done!"
p csv_path
