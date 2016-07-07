##replacing company specific info with ###CHANGEME###
require 'rubygems'
require 'pg'
require '###CHANGEME###.rb'
require 'rio'
require 'date'

$logger = ###CHANGEME###.create(STDOUT)

dbuser="username"

###############################################################################
# Specify DB
conn = PGconn.new('host', port, nil, nil, 'dbname', dbuser)

###############################################################################
# Quit unless our script gets 1 command line arguments expected CONVfilename
$import_file_name = ARGV[0]
unless ARGV.length == 1
  puts "Usage: missing target file\n"
  exit
end

###############################################################################
# Variables
unique_id = []
$record_counter=1
$new_patient_id=''
$first_name=''
$date_of_birth=''
$old_patient_id=''
$npi=''
$store_id=''
$client_id=''

###############################################################################
# Main Part Of Script
array_file = File.read("#{$import_file_name}").split("\n").map(&:strip)
array_file.each do |row|
  column = row.split('|')

  $new_patient_id=column[0]
  $first_name=column[1]
  $first_name.gsub!("'"," ")
  $dob=column[2]
  $date_of_birth=Date.strptime("#{$dob}", "%Y%m%d")
  $old_patient_id=column[3]
  $npi=column[4]
  $prc_file=ENV['HOME'] + "/###CHANGEME###/###CHANGEME###_#{$npi}.conv"

  if $npi.nil? || $npi.empty? || $old_patient_id.nil? || $old_patient_id.empty? || $new_patient_id.nil? || $new_patient_id.empty? || ($old_patient_id == $new_patient_id)
    $logger.warn("Missing information or matching patient ids in row #{$record_counter}. Skipping...")
  else
    pfile = rio($prc_file)
    if ! pfile.exist?
      pfile.touch
    end
    processed = File.read("#{$prc_file}").split("\n").map(&:strip)

    ###############################################################################
    # If new pat id does not exist in unique array or in processed file continue
    if ! processed.include?($new_patient_id) && ! unique_id.include?($new_patient_id)
      unique_id.insert(0,$new_patient_id)

      ###############################################################################
      ## return clientid and store number from NPI
      client_search = conn.exec("select cs.storeid, ccs.clientid from ###CHANGEME### cs join ###CHANGEME### ccs on ccs.storeid = cs.storeid where cs.npi ='#{$npi}';")
      $store_id=client_search[0]['storeid']
      $client_id=client_search[0]['clientid']

      ###############################################################################
      # Start of data comparing
      begin
        results = conn.exec("select pi.pharmacypatientid, pi.###CHANGEME### from patient.###CHANGEME### pi
                             JOIN patient.patientdemographic pd on pd.a###CHANGEME###=pi.###CHANGEME###
                             JOIN patient.patientname pn on pn.###CHANGEME###=pi.###CHANGEME###
                             where pi.clientid='#{$client_id}' and pi.storeid='#{$store_id}' and pn.firstname ilike '#{$first_name}%' and pd.dateofbirth='#{$date_of_birth}' and pi.pharmacypatientid='#{$old_patient_id}';")

        if results.num_tuples.zero? # If the above query doesn't find a match then we assume that patient doesn't need converted
          $logger.info("New Patient ID: #{$new_patient_id} doesn't need converting. Skipping...")

        else #update the patient ID to the new one in patient.###CHANGEME### and ###CHANGEME###.###CHANGEME###
          $logger.info("New Patient ID: #{$new_patient_id} submitted for updating.")
          pap_results = conn.exec("UPDATE patient.###CHANGEME###
                                  SET pharmacypatientid='#{$new_patient_id}'
                                  WHERE clientid='#{$client_id}' and storeid='#{$store_id}' and
                                  pharmacypatientid='#{$old_patient_id}' and
                                  ###CHANGEME###='#{results[0]['###CHANGEME###']}';")
          acp_results = conn.exec("UPDATE ###CHANGEME###.###CHANGEME###
                                   SET externalpatientid='#{$new_patient_id}'
                                   WHERE storeuid IN (SELECT ###CHANGEME### FROM client.store WHERE storeid='#{$store_id}') and
                                   externalpatientid='#{$old_patient_id}' and
                                   ###CHANGEME###='#{results[0]['###CHANGEME###']}';")
        end
      rescue PG::Error => err
        error_string = "SQL ERROR | #{err.result.result_error_message}"
        $logger.error(error_string)
        $logger.error("Failed to update new Patient ID: #{$new_patient_id} due to above error.  Skipping...")
      end
    end
  end
  $record_counter+=1
end
unique_id.each do |i|
  rio($prc_file) << "#{i}\n"
end
