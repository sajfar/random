##replacing company specific info with ###CHANGEME###
require 'set'
require 'yaml'
require 'net/ssh'
require 'active_record'
require 'date'
require 'time_difference'

# Constants
@hostname = ''
@user = ''
@password = ''
@logger = Logger.new(File.open('../log/mdf_crawler.log', 'a'))
@stores_cmd = "awk -F \"|\" '{ print $59 }' "
@stores_2_cmd = ' | sort | uniq'
@filled_date_cmd = "awk -F \"|\" '{ print $48 }' "
@sold_date_cmd = "awk -F \"|\" '{ print $47 }' "
@rx_status_cmd = "awk -F \"|\" '{ print $49 }' "
@sold_2_cmd = ' | wc -l' # total record count
@sold_3_cmd = ' | grep 2' # filled   ## i think this needs to be changed
@sold_4_cmd = ' | grep 3' # sold
@stores_in_file = Array.new
@stores_not_found = Array.new
@file_date = nil
@filename = ''
@filesize = 0
@missing_stores = ''
@cad_dir_location = ''
@store_string = ''

# Sold Data Variables
@total_records = 0
@filled_records = 0
@sold_records = 0
@store_found_count = 0

# Active Record Logging
ActiveRecord::Base.logger = Logger.new(File.open('../log/mdf_crawler.log', 'w'))

ActiveRecord::Base.establish_connection(
    adapter:    'postgresql',
    database:   '',
    encoding:    'unicode',
    host: '',
    post: '',
    username: 'dashboard',
    password: '',
    schema_search_path: ''
)

class StoreIssue < ActiveRecord::Base
  self.table_name = 'client_info.store_issues'
end

class MdfClient < ActiveRecord::Base
  self.table_name = 'client_info.mdf_clients'
end

# Main Logging Method
def log_it(log_type, calling_method, message)
  # Console Logging
  puts "#{log_type} | #{DateTime.now} | #{calling_method} | Message: #{message}"
  # File Logging
  #case log_type
   #when 'DEBUG'
   #  @logger.debug "#{calling_method} | Message: #{message}"
   #when 'INFO'
   #  @logger.info "#{calling_method} | Message: #{message}"
   #else
   #  @logger.info "#{calling_method} | Unknown Logging Error..."
  #end
end

# Exception Logging Method
def log_it_ex(log_type, calling_method, message, backtrace)
  # Console Logging
  puts "#{log_type} | #{DateTime.now} | #{calling_method} | Message: #{message} | Backtrace: #{backtrace}"
  # File Logging
  #case log_type
  #  when 'ERROR'
  #    @logger.error "#{calling_method} | Message: #{message} | Backtrace: #{backtrace}"
  #  when 'FATAL'
  #    @logger.fatal "#{calling_method} | Message: #{message} | Backtrace: #{backtrace}"
  #  else
  #    @logger.info "#{calling_method} | Unknown Logging Error..."
  #end
end

def clear_variables
  @total_records = 0
  @filled_records = 0
  @sold_records = 0
  @store_found_count = 0
  @stores_in_file.clear
  @stores_not_found.clear
  @filename = ''
  @missing_stores = ''
  @filesize = 0
end

def get_date
  @file_date = DateTime.now
end

def clean_filename(filename) # removes new line
  cleaned_filename = filename[1..-1]
  cleaned_filename = cleaned_filename[1..-1]
end

def split_filenames
  file_list = @filename
  @filename = ''
  filename_split = file_list.split("\n")
  i = 0
  while i < filename_split.size do
    cleaned_filename = clean_filename(filename_split[i])
    if i == filename_split.size-1
      @filename += " #{cleaned_filename}"
    else
      @filename +="#{cleaned_filename}, "
    end
    i += 1
  end
end

# Parse filesize from 'ls' line
def get_file_size(line)
  split_line = line.split(' ')
  #logit("DEBUG", "get_file_size", "File #{split_line[8]} size is - #{split_line[4]}")
  @filesize = split_line[4]
end

def standard_filled_sold_proc(ssh, customer, directory, filename )
  @store_filled_sold_hash = Hash.new{|hsh,key| hsh[key] = [0,0,0] }
  if customer == '###CHANGEME###' || customer == '###CHANGEME###' || customer == '###CHANGEME###'  # No Calcs for ###CHANGEME### at this time
    record_cmd = "#{@stores_cmd}#{directory}#{filename}#{@sold_2_cmd}"
    @total_records = ssh.exec!(record_cmd)
    @filled_records = 0.0
    @sold_records = 0.0
  else
    record_cmd = "#{@stores_cmd}#{directory}#{filename}#{@sold_2_cmd}"  # keep record count from mdf
    @total_records = ssh.exec!(record_cmd)

      @pull_store_status ="awk -F \"|\" '{ print $59, $49 }' "
      status_cmd = "#{@pull_store_status}#{directory}SDF*#{filename}"
      tmp_filled_sold = ssh.exec!(status_cmd)
      tmp_array = tmp_filled_sold.split("\n")

      @total_sold_count = 0
      @total_fill_count = 0

      tmp_array.each do |num_status|
        tmp_array = num_status.split(' ')

        store = tmp_array[0]
        status = tmp_array[1]

          if status == '0' || status == '2' #fill
            @store_filled_sold_hash[store][0]+=1
            @store_filled_sold_hash[store][2]+=1
            @total_fill_count+=1
          elsif status == '3' #sold
            @store_filled_sold_hash[store][1]+=1
            @store_filled_sold_hash[store][2]+=1
            @total_sold_count +=1
          else
            @store_filled_sold_hash[store][2]+=1
          end

      end

      @filled_records = @total_fill_count
      @sold_records = @total_sold_count
      log_it('INFO', 'standard_filled_sold_proc', "Client: #{customer} SDF: #{@pull_store_status}#{directory}SDF*#{filename} Filled Records: #{@filled_records} Sold Records: #{@sold_records}")
      @store_string = @store_filled_sold_hash.to_s
      @store_string.gsub!(/[\{}">=]/,'')

  end
end

def get_data_from_mdf(customer, directory, db_stores)
  clear_variables
  log_it('DEBUG', 'get_data_from_mdf', "Connecting to account: #{@user} on host: #{@hostname}")
  Net::SSH.start(@hostname, @user, :password => @password) do |ssh|
    filename = "#{customer}_Master*#{@file_date.strftime('%Y%m%d')}*.txt"
    full_cmd = @stores_cmd + directory + filename + @stores_2_cmd
    filesize_cmd = "du #{directory}#{filename} -c | grep total | sed 's/[^0-9]*//g'"
    @filesize = ssh.exec!(filesize_cmd)
    log_it('INFO', 'get_data_from_mdf', "Client: #{customer} MDF Filesize: #{@filesize}")

    awk_output = ssh.exec!(full_cmd)
    if awk_output.include?('cannot open file')
      log_it('ERROR', 'get_data_from_mdf', "File: #{directory}#{filename} was not found on #{@hostname}")
      @filename = "Today's MDF was not found."
    else
      @stores_in_file = awk_output.split("\n") # @stores_in_file need to be compared to db
      # Process Filled/Sold Data
      standard_filled_sold_proc(ssh, customer, directory, filename)
      filename_cmd = "cd #{directory}; find -name \"#{filename}\""
      @filename = ssh.exec!(filename_cmd)
      if @filename.lines.count > 1
        split_filenames
      else
        @filename = clean_filename(@filename)
      end
      compare_mdf_to_db(db_stores)
    end
  end
end

def compare_mdf_to_db(db_stores) # pass stores array from db
  @store_found_count = 0
  db_stores_array = db_stores.split(',')
      db_stores_array.each do |store|
        store.gsub!(/\D/, '')
        store_is_found = false
        @stores_in_file.each do |mdf_store|
          if mdf_store.to_i == store.to_i
            store_is_found = true
            @store_found_count += 1
            break
          end
        end
        @stores_not_found.push(store) unless store_is_found
      end
end

def search_db_records(customer)  #find entries that already exist for todays date and update if so
  old_issues = StoreIssue.all
  old_issues.each do |old_issue|
    if old_issue.customer == customer
      old_date = old_issue.date
      if old_date.strftime('%Y%m%d') == @file_date.strftime('%Y%m%d')
        return old_issue
      end
    end
  end
  nil
end

def build_db_record(customer, db_client_id) # pass customer name expected
  issue = StoreIssue.new

  old_issue = search_db_records(customer)
  issue = old_issue if old_issue != nil
    if @stores_not_found.first == 'X'
      @missing_stores = "No File on #{@file_date.strftime('%m-%d-%Y')} for #{customer}"
      @filename = 'No File'
    else
      @missing_stores = @stores_not_found.join(',')
    end
      issue.customer = customer
      issue.client_id = db_client_id
      issue.filename = @filename.gsub("\n", '') if @filename != ''
      issue.date = @file_date
      issue.filesize = @filesize
      issue.missing_stores = @missing_stores
      issue.filled_records = @filled_records
      issue.sold_records = @sold_records
      issue.total_records = @total_records
      issue.stores_found = @store_found_count
      issue.store_filled_sold_data = @store_string
      #puts "#{issue.filename} | #{issue.date} | #{issue.missing_stores} | #{issue.filled_records} | #{issue.sold_records} | #{issue.total_records}"
      issue.save
end

###############################################################################
#
# Start of Script
#
###############################################################################
# Get Todays Date
get_date

db_mdf_clients = MdfClient.all
db_mdf_clients.each do |info|
  db_client_name = info.client_name
  db_client_id = info.client_id
  db_camp_dir = "#{@cad_dir_location}#{info.client_dp_campdir_name}"
  db_mdf_prefix = info.client_dp_file_prefix
  db_store_list = info.client_stores

  get_data_from_mdf(db_mdf_prefix, "#{db_camp_dir}/archivefiles/", db_store_list)
  build_db_record(db_client_name, db_client_id)
end
