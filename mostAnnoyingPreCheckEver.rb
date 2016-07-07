##replacing company specific info with ###CHANGEME###
# For the record, I hate this script and think there's a way better way to do it - assignments are assignments and it was for v1.8.7
#!/usr/bin/ruby

###############################################################################
## 
## Functions
## 
###############################################################################

def logit(reason, key, record_num) # log function that is expecting a description variable

 case reason
  when 'null'
   $null_count += 1
   text="Null | #{key} | #{record_num}"
  when 'length'
   $length_count += 1
   text="Value Length | #{key} | #{record_num}"
  when 'char'
   $char_count += 1
   text="Invalid Character | #{key} | #{record_num}"
  when 'format'
   $format_count += 1
   text="Format Issue | #{key} | #{record_num}"
  when 'field'
   $field_count += 1
   text="Invalid Field Count | #{record_num}"
    else
      text="How did this happen? | #{key} | #{record_num}"
 end

File.open("#{$import_file_name}.chklog", 'a') {|f| f.print "#{text} \n" }

end

class Numeric
  def percent_of(n)
    self.to_f / n.to_f * 100.0
  end
end

def stats

  File.open("#{$import_file_name}.chklog", 'a') {|f| f.print "\n Total Fields: #{$num_of_fields}\n Total Rows: #{$row_counter} \n Required Fields with Null: #{$null_count} \n Length Issues: #{$length_count} \n Character Issues: #{$char_count} \n Formatting Issues: #{$format_count} \n Rows With Not Enough Fields: #{$field_count} %#{($field_count.to_f / $row_counter.to_f * 100).round } \n " }
end


def required_check(key, value, record_num)

 if value.nil? || value.strip.empty?
         logit('null', key, record_num) #{key} field in row #{recordNum}")
 else
  case key # only check the required fields based off what we expect

   when 'patientLastName', 'patientFirstName' # Expected Alpha 32 char
    if value.length > 32
     logit('length', key, record_num)
    elsif value.match(/(?![ ])[0-9\?<>,\[\]\}\{=\)\(\*&\^%\$#\/`~!@_\+]/)
     logit('char', key, record_num)
    end  

   when 'patientDOB'  # YYYYMMDD Date 8 digits
    if value.length > 8
     logit('length', key, record_num)
    elsif value[0,1] =~ (/[03-9]/) || value[4,1] =~ (/[2-9]/) || value[6,1] =~ (/[4-9]/)
     logit('format', key, record_num)
    elsif value.match(/(?![ ])\D/)
     logit('char', key, record_num)
    end

   when 'patientState'  # alpha 2 char
    if value.length > 2
     logit('length', key, record_num)
    elsif value.match(/(?![ ])[0-9\W]/)
     logit('char', key, record_num)
    end

   when 'patientZipCode'  # numeric min 5 max 9 - need to keep leading 0s
    if value.length < 5 || value.length > 9
     logit('length', key, record_num)
    elsif value.strip.match(/(?![ ])\D/)
     logit('char', key, record_num)
    end

   when 'npi' # numeric 10 digits
    if value.length < 10 || value.length > 10
     logit('length', key, record_num)
    elsif value.match(/(?![ ])\D/)
     logit('char', key, record_num)
    end

   when 'prescriptionNumber'  # numeric 7 digits
    if value.length > 7
     logit('length', key, record_num)
    elsif value.match(/(?![ ])\D/)
     logit('char', key, record_num)
    end

   when 'medicationName'  # alpha-numeric 32 char
    if value.length > 32
     logit('length', key, record_num)
    elsif value.match(/(?![ ])[\?<>',\[\]\}\{=\*\^\$#`~!@_\+]/)
     logit('char', key, record_num)
    end

   when 'daysSupply'  # numeric 3 digits
    if value.length > 3
     logit('length', key, record_num)
    elsif value.match(/(?![ ])\D/)
     logit('char', key, record_num)
    end

   when 'refillsOrig', 'refillsRemaining' # alpha-numeric 3 char
    if value.length > 3
     logit('length', key, record_num)
    elsif value.match(/(?![ ])[\?<>',\[\]\}\{=\)\(\*&\^%\$#`~!@_.\/\-\+]/)
     logit('char', key, record_num)
        end

   when 'prescriptionStatus'  # numeric 2 digit 1-7 87 - 89
    if value.length != 2
     logit('length', key, record_num)
    elsif value.match(/(?![ ])\D/) || value.to_i < 0 || (value.to_i > 17 && value.to_i < 87) || value.to_i > 89
     logit('char', key, record_num)
        end

   when 'pharmacyNumber'  # numeric 8 digits - need to keep leading 0s
    if value.length > 8
     logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

   when 'NDCNumber' # numeric 11 digits
    if value.length > 11
     logit('length', key, record_num)
    elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      else
        logit('wha?', key, record_num)  # catch all
  end
 end
end

def not_required_check(key, value, record_num)

  if value.nil? || value.strip.empty?
    #logit('null', key, record_num) #{key} field in row #{recordNum}")
  else
    case key
    when 'pharmacyPatientID'        # alpha numeric 20 digit
        if value.length > 20
         logit('length', key, record_num)
        elsif value.match(/(?![ ])[\?<>',\[\]\}\{=\)\(\*&\^%\$\/#`~!@_.\-\+]/)
          logit('char', key, record_num)
        end

      when 'personCode' # 1 num between 1..4
        if value.length > 1
          logit('length', key, record_num)
        elsif value.match(/\D/) || value.to_i < 0 || value.to_i > 4
          logit('char', key, record_num)
        end

      when'patientMiddleInitial' # 1 char alpha
        if value.length > 1
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[0-9\W_]/)
          logit('char', key, record_num)
        end

      when 'patientPrefix', 'patientSuffix' # alpha 5
        if value.length > 5
          logit('length', key, record_num)
        elsif value.match(/(?![ .])[0-9\W_]/)
          logit('char', key, record_num)
        end

      when 'patientGender' # 1 num only 1 or 2
        if value.length > 1
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/) || value.to_i < 1 || value.to_i > 2
          logit('char', key, record_num)
        end

      when 'patientAddress1', 'patientAddress2', 'address1', 'address2' # alpha num 32 chars
        if value.length > 32
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[\?<>',\[\]\}\{=\)\(\*&\^%\$#`\/~!@_\+]/)
          logit('char', key, record_num)
        end

      when 'patientCity', 'city' # alpha 32 char ignore whitespace
        if value.length > 32
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[0-9\W_]/)
          logit('char', key, record_num)
        end

      when 'patientPhoneNumber', 'phoneNumber', 'faxNumber', 'patientAlternate'  # 10 digit num
        if value.length > 10
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'patientEmail'
        if value.length > 32 # alpha num 32 char "." , "@" , "_" , "-" are okay
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[\?<>',\[\]\}\{=\)\(\*&\^%\$#`~!\/\+]/)
          logit('char', key, record_num)
        end

      when 'ncpdpid'
        if value.length > 7 # num 7
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'prescriberIDQualifier' # 2 num 1..7, 9..11, 13, 99
        if value.length > 2
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/) || value.to_i < 0 || value.to_i == 8 || value.to_i == 12 || (value.to_i > 13 && value.to_i < 99) || value.to_i > 99
          logit('char', key, record_num)
        end

      when 'prescriberID'  # num 15
        if value.length > 15
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'DEAnumber' # alpha num 15 char
        if value.length > 15
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\W/)
          logit('char', key, record_num)
        end

      when 'stateLicenseNumber', 'prescriber', 'PCN' # alpha num 10
        if value.length > 10
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\W/)
          logit('char', key, record_num)
        end

      when 'lastName', 'firstName' # alpha 32
        if value.length > 32
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[0-9\?<>,\[\]\}\{=\)\(\*&\^%\$#\/`~!@_\+]/)
          logit('char', key, record_num)
        end

      when 'middleName' # alpha 20
        if value.length > 20
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[0-9\?<>,\[\]\}\{=\)\(\*&\^%\$#\/`~!@_\+]/)
          logit('char', key, record_num)
        end

      when 'prefix','suffix' # alpha 5
        if value.length > 5
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[0-9\?<>,\[\]\}\{=\)\(\*&\^%\$#\/`~!@-_\+]/)
          logit('char', key, record_num)
        end

      when 'state' #alpha 2
        if value.length > 2
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[0-9\W_]/)
          logit('char', key, record_num)
        end

      when 'zipCode' # num 5 - 9
        if value.length < 5 || value.length > 9
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'fillNumber' # num 2 0-99
        if value.length > 2
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/) || value.to_i < 0 || value.to_i > 99
          logit('char', key, record_num)
        end

      when 'productIDQualifier' # num 2 1-4 or 99
        if value.length > 2
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/) || value.to_i < 0 || (value.to_i > 4 && value.to_i < 99) || value.to_i > 99
          logit('char', key, record_num)
        end

      when 'productID' # num 32
        if value.length > 32
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'quantity' # num 6 "." ok
        if value.length > 6
          logit('length', key, record_num)
        elsif value.match(/(?![ .])\D/)
          logit('char', key, record_num)
        end

      when 'SIGtext' # alpha num 120 char
        if value.length > 120
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\W/)
          logit('char', key, record_num)
        end

      when 'dosage' # num 3
        if value.length > 3
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'dateWritten', 'dateFilled', 'datePickedUp', 'origFillDate', 'RXExpirationDate', 'shipmentDate', 'estimatedDeliveryDate' , 'prescriptionReadyDate', 'contactedPrescriberDate', 'prescriberDeniedDate', 'prescriberApprovedDate' # Date YYYYMMDD
        if value.length > 8
          logit('length', key, record_num)
        elsif value[0,1] =~ (/[03-9]/) || value[4,1] =~ (/[2-9]/) || value[6,1] =~ (/[4-9]/)
          logit('format', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'patientPaid', 'amountofCoPay'
        if value.length > 8
          logit('length', key, record_num)
        elsif value.match(/(?![ .])\D/)
          logit('char', key, record_num)
        end

      when 'BIN' # num 6
        if value.length > 6
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'groupID', 'memberID', 'cardholderID' # alpha num 32
        if value.length > 32
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\W/)
          logit('char', key, record_num)
        end

      when 'patientLanguage' # num 2  1 or 2
        if value.length > 6
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/) || value.to_i < 1 || value.to_i > 2
          logit('char', key, record_num)
        end

      when 'autoFillIndicator' # alpha 1 "Y" "N" "M"
        if value.length > 1
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[0-9\W_]/) || value.to_s != 'Y' && value.to_s != 'M' && value.to_s != 'N'
          logit('char', key, record_num)
        end

      when 'DAWCode' # num 1  can be 0-9
        if value.length > 1
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/) || value.to_i < 0 || value.to_i > 9
          logit('char', key, record_num)
        end

      when 'timePickedUp' # HHMM num 4
        if value.length > 4
          logit('length', key, record_num)
        elsif value[0,1] =~ (/[3-9]/) || value[2,1] =~ (/[7-9]/)
          logit('format', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'prescriptionOrigin' # num 1 1-5
        if value.length > 1
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/) || value.to_i < 1 || value.to_i > 5
          logit('char', key, record_num)
        end

      when 'shipperCarrierID' # alpha 5 USPS UPS FEDEX DHL POM POS ignore case
        if value.length > 5
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[0-9\W_]/) || value.upcase.to_s != 'USPS' && value.upcase.to_s != 'UPS' && value.upcase.to_s != 'FEDEX'  && value.upcase.to_s != 'DHL' && value.upcase.to_s != 'POM' && value.upcase.to_s != 'POS'
          logit('char', key, record_num)
        end

      when 'shipmentTracking'  # alpha num 20
        if value.length > 20
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\W/)
          logit('char', key, record_num)
        end

      when 'patientPreferredContactMethod' # num 1 1-3 or 9
        if value.length > 1
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/) || value.to_i < 1 || (value.to_i > 3 && value.to_i < 9) || value.to_i > 9
          logit('char', key, record_num)
        end

      when 'medispan' # alpha 1   O N Y M
        if value.length > 1
          logit('length', key, record_num)
        elsif value.match(/(?![ ])[0-9\W_]/) || value.upcase.to_s != 'Y' && value.upcase.to_s != 'M' && value.upcase.to_s != 'N'
          logit('char', key, record_num)
        end

      when 'shipmentMethod' # alpha num 2  01-05, 3B,4B, 1D,2D,3D,GR,1C
        if value.length > 2
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\W/) || value.upcase.to_s != '01' && value.upcase.to_s != '02' && value.upcase.to_s != '03' && value.upcase.to_s != '04' && value.upcase.to_s != '05' && value.upcase.to_s != '3B' && value.upcase.to_s != '4B' && value.upcase.to_s != '1D' && value.upcase.to_s != '2D' && value.upcase.to_s != '3D' && value.upcase.to_s != 'GR' && value.upcase.to_s != '1C'
          logit('char', key, record_num)
        end

      when 'productCost', 'totalPrice' # num 10
        if value.length > 10
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/)
          logit('char', key, record_num)
        end

      when 'paymentType' # num 2  01-06
        if value.length > 2
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\D/) || value.to_i < 1 || value.to_i > 6
          logit('char', key, record_num)
        end

      when 'longTermCareCode' # alpha num 10
        if value.length > 10
          logit('length', key, record_num)
        elsif value.match(/(?![ ])\W/)
          logit('char', key, record_num)
        end

      else
        logit('wha?', key, record_num)  # catch all
    end
 end
end 

###############################################################################
## 
## Global Variables/Variables
## 
###############################################################################

$import_file_name = ARGV[0]
$num_of_fields = 89
$row_counter = 0
$null_count = 0
$length_count = 0
$char_count = 0
$format_count = 0
$field_count = 0

###############################################################################
## 
## Main/Start of Script
## 
###############################################################################

File.open("#{$import_file_name}.chklog", 'w') {|f| f.print '' }

# quit unless our script gets two command line arguments
unless ARGV.length == 1
     puts "Usage: ruby importPreCheck.rb mdfFile.bleh\n"
     exit
end

array_file = File.read("#{$import_file_name}").split("\n").map(&:strip)

# Log the number of fields in a row

array_file.each do |row|
 record = row.split('|')
  $row_counter += 1
# Assigning corresponding array values to a hash as human readable 
  record_data = {"pharmacyPatientID" => record[0], "personCode" => record[1], "patientLastName" => record[2], "patientFirstName" => record[3], "patientMiddleInitial" => record[4], "patientPrefix" => record[5], "patientSuffix" => record[6], "patientDOB" => record[7], "patientGender" => record[8], "patientAddress1" => record[9], "patientAddress2" => record[10], "patientCity" => record[11], "patientState" => record[12], "patientZipCode" => record[13], "patientPhoneNumber" => record[14], "patientEmail" => record[15], "ncpdpid" => record[16], "npi" => record[17], "prescriberIDQualifier" => record[18], "prescriberID" => record[19], "DEAnumber" => record[20], "stateLicenseNumber" => record[21], "prescriber" => record[22], "lastName" => record[23], "firstName" => record[24], "middleName" => record[25], "prefix" => record[26], "suffix" => record[27], "address1" => record[28], "address2" => record[29], "city" => record[30], "state" => record[31], "zipCode" => record[32], "phoneNumber" => record[33], "faxNumber" => record[34], "prescriptionNumber" => record[35], "fillNumber" => record[36], "productIDQualifier" => record[37], "productID" => record[38], "medicationName" => record[39], "quantity" => record[40], "daysSupply" => record[41], "SIGtext" => record[42], "dosage" => record[43], "dateWritten" => record[44], "dateFilled" => record[45], "datePickedUp" => record[46], "refillsOrig" => record[47], "prescriptionStatus" => record[48], "patientPaid" => record[49], "amountofCoPay" => record[50], "BIN" => record[51], "PCN" => record[52], "groupID" => record[53], "memberID" => record[54], "cardholderID" => record[55], "patientAlternate" => record[56], "patientLanguage" => record[57], "pharmacyNumber" => record[58], "autoFillIndicator" => record[59], "DAWCode" => record[60], "origFillDate" => record[61], "refillsRemaining" => record[62], "RXExpirationDate" => record[63], "NDCNumber" => record[64], "timePickedUp" => record[65], "prescriptionOrigin" => record[66], "shipmentDate" => record[67], "shipperCarrierID" => record[68], "shipmentTracking" => record[69], "estimatedDeliveryDate" => record[70], "patientPreferredContactMethod" => record[71], "medispan" => record[72], "shipmentMethod" => record[73], "productCost" => record[74], "totalPrice" => record[75], "paymentType" => record[76], "prescriptionReadyDate" => record[77], "contactedPrescriberDate" => record[78], "prescriberDeniedDate" => record[79], "prescriberApprovedDate" => record[80], "longTermCareCode" => record[81]}


# Log the number of fields in a row if an error is found the data will not be processed
 if record.length > $num_of_fields || record.length < $num_of_fields
  logit('field', $num_of_fields, $row_counter)
 else
  ## Call functions to check data
  record_data.each do |key, value|
   case key # only send the required fields to be checked
    when "patientLastName", "patientFirstName" ,"patientDOB", "patientState", "patientZipCode", "npi", "prescriptionNumber", "medicationName", "daysSupply", "refillsOrig", "prescriptionStatus", "pharmacyNumber", "refillsRemaining", "NDCNumber"
     required_check(key, value, $row_counter)
    else 
     not_required_check(key, value, $row_counter)
   end
  end #of function check loop
 end 
end #of main array reading loop

stats
