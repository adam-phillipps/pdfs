require 'pdf-reader'
require 'byebug'
require 'awesome_print'

class PdfParser
  def initialize
    # command line method to take file name, if it's something useful
    # @file = 'PatientReport_20151028.PDF'
    @file = ARGV.empty? ? "PatientReport_20151028.PDF" : ARGV[0]
    individualized_and_mapped_records_array = build_data_hashes_from_records
    individualized_and_mapped_records_array[individualized_and_mapped_records_array.count - 2][:patient_number] = individualized_and_mapped_records_array.last[:patient_number] 
    unique_records = unique(individualized_and_mapped_records_array)
    byebug
    dump_records_to_csv(individualized_and_mapped_records_array)
  end

  def build_data_hashes_from_records
    records_array = []
    records.map do |record|
      records_array <<
        {
          patient_number:     ((record.match(/(\d{4}).*(?= Default\sAccount:)/xim).captures[0] rescue nil) || '0000000'),
          name:               (record.match(/(?<= \d{4})(.*?)(?= Default\sAccount)/xi).captures[0] rescue nil),
          home_phone:         (record.match(/(?<= Home:)\s*\((\d{3})\)\s(\d{3})-(\d{4})/xm).captures.join('') rescue nil),
          default_account:    (record.match(/(?<= Default\sAccount:)\s*(\d*)/xm).captures[0] rescue nil),
          class:              (record.match(/(?<= Class:)\s*(\w*)/xm).captures[0] rescue nil),
          ssn:                (record.match(/(?<= SSN:)\s*(\d{3}\-\d{2}\-\d{4})/xm).captures[0] rescue nil),
          sex:                (record.match(/(?<=Sex:)\s*(\w*)Emp\s*Status/i).captures[0] rescue nil),
          emp_status:         (record.match(/Emp Status:\s*(\w*)/i).captures[0] rescue nil),
          chart_num:          (record.match(/Chart #:\s*(.*)DOB/).captures[0] rescue nil),
          dob:                (record.match(/DOB:\s*(\d{1,2}\/\d{1,2}\/\d{2,4})/i).captures[0] rescue nil),
          employee_id:        (record.match(/Employee\sID:\s*([\w\d-]*)/).captures[0] rescue nil),
          registered:         (record.match(/(?<=Registered:)\s*(\d{1,2}\/\d{1,2}\/\d{2,4})Race/xm).captures[0]  rescue nil),
          race_ethnicity:     (record.match(/Race.*Ethnicity:(.*)Employer:/xm).captures[0] rescue nil),
          employer:           (record.match(/Employer:(.*)First\sVisit/xm).captures[0] rescue nil),
          first_visit:        (record.match(/First\sVisit:\s*(\d{1,2}\/\d{1,2}\/\d{2,4})/xm).captures[0] rescue nil),
          lang:               (record.match(/Lang:\s*(\w)*/i).captures[0] rescue nil),
          last_visit:         (record.match(/last visit:\s*(\d{1,2}\/\d{1,2}\/\d{2,4})/i).captures[0] rescue nil),
          marital:            (record.match(/Marital:\s*(\w*)/i).captures[0] rescue nil),
          email:              (record.match(/email:(.*?)Home:/i).captures[0] rescue nil),
          home:               (record.match(/Home:\s*\((\d{3})\)\s(\d{3})-(\d{4})/i).captures.join('') rescue nil),
          consent:            (record.match(/consent:(YES|NO)/i).captures[0] rescue nil),
          assigned:           (record.match(/assigned:(.*?)Work/i).captures[0] rescue nil),
          work:               (record.match(/work:.*?(\d{3})\)\s(\d{3})-(\d{4})Referral/i).captures.join('') rescue nil),
          referral_src:       (record.match(/Referral\sSrc:\s*(.*?)Referring:/i).captures[0] rescue nil),
          referring:          (record.match(/Referring:(.*?)Emergency/i).captures[0] rescue nil),
          mobile:             (record.match(/mobile:\s\((\d{3})\)\s(\d{3})-(\d{4})/i).captures.join('') rescue nil),
          accounts:           (record.match(/.\Z/).captures[0] rescue nil)
        }
    end
    byebug
    records_array
  end

  def dump_records_to_csv
    # do some stuff to put this in a csv or whatever you guys wanted
  end

  def pages
    # @pages ||= reader.pages.map { |page| page.text }
    @pages ||= (0..3).map { |i| reader.pages[i].text }
  end
    
  def reader
    @reader ||= PDF::Reader.new(@file)
  end

  def records
    @records ||= pages.join(',').scan(/(\d{4}.{1,40}Default\sAccount:.*?)(?= \d{4}.{1,40}Default\sAccount)/xm).flatten
  end

  def unique(recs)
    i = 0
    recs.map do |rec|
      if i < recs.count - 1
        if rec[:patient_number] == recs[i += 1][:patient_number]
          rec.merge(recs[i])
        end
        rec
      end
    end
  end
end

PdfParser.new