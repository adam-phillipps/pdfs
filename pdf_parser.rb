require 'pdf-reader'
require 'csv'
require 'byebug'
require 'awesome_print'

class PdfParser
  def initialize
    @file = ARGV.empty? ? "PatientReport_20151028.PDF" : ARGV[0]
    individualized_and_mapped_records_array = build_data_hashes_from_records
    # unique_records = unique(individualized_and_mapped_records_array)
    dump_records_to_csv(individualized_and_mapped_records_array, 'PatientReport_20151028.csv')
  end

  def build_data_hashes_from_records
    records_array = []
    count = 0
    records.map do |record|
      record.gsub!(',', '\,')
      account_info = (record.match(/(?<= Accounts:).*?(?<= NumberGuarantorAcct\sFinance\sGrpDefaultStatusBalance)(.*)\Z/xim).captures[0] rescue '')
      ins_policy = (account_info.match(/(?= Ins\sPolicies:)(.*)\Z/xim).captures[0] rescue '')
      records_array <<
        {
          accounts:           {
                                account_finance_grp:   (account_info.match(/\w([A-Z]{2,})([A-Z]\s+|[A-Z]{2}.*)\d*\.\d*/).captures[0] rescue ''),
                                balance:               (account_info.match(/(\d*\.\d*)((?= \\nIns\.\sPolicies:)|\Z)/xm).captures[0] rescue ''),
                                default:               (account_info.match(/(Y|N)[A-Z][a-z]*\d*\.\d*/).captures[0] rescue ''),
                                guarantor:             (account_info.match(/\A.*\d(.*?)[A-Z]{2}/xm).captures[0] rescue ''),
                                number:                (account_info.match(/(?<= \A\\n)(\d*)\w*\,/).captures[0] rescue ''),
                                status:                (account_info.match(/([A-Z][a-z]*)\d+\.\d*/).captures[0] rescue '')
          },
          address:            (record.match(/(?<= Status:).*?\n(.*?)(?= Chart\s\#:).*\n(.*?\d{5})(?= Registered:)?/xi).captures.join(' ') rescue ''), 
          assigned:           (record.match(/assigned:(.*?)Work/i).captures[0] rescue ''),
          chart_num:          (record.match(/Chart #:\s*(.*)DOB/).captures[0] rescue ''),
          consent:            (record.match(/consent:(YES|NO)/i).captures[0] rescue ''),
          class:              (record.match(/(?<= Class:)\s*(\w*)/xm).captures[0] rescue ''),
          default_account:    (record.match(/(?<= Default\sAccount:)\s*(\d*)/xm).captures[0] rescue ''),
          dob:                (record.match(/DOB:\s*(\d{1,2}\/\d{1,2}\/\d{2,4})/i).captures[0] rescue ''),
          email:              (record.match(/([\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+)/i).captures[0] rescue ''),
          emp_status:         (record.match(/Emp Status:\s*(\w*)/i).captures[0] rescue ''),
          employee_id:        (record.match(/Employee\sID:\s*([\w\d-]*)\n/xi).captures[0] rescue ''),
          employer:           (record.match(/(?<= Employer:)\s*(.*)\n(?= First\sVisit:)/x).captures[0] rescue ''),
          first_visit:        (record.match(/First\sVisit:\s*(\d{1,2}\/\d{1,2}\/\d{2,4})/xm).captures[0] rescue ''),
          home:               (record.match(/(?<= Home:)\s*\((\d{3})\)\s(\d{3})-(\d{4})/xm).captures.join('') rescue ''),
          ins_policies:       {
                                accept_assign:         (ins_policy.match(//).captures[0] rescue ''),
                                group:                 (ins_policy.match(//).captures[0] rescue ''),
                                plan:                  (ins_policy.match(//).captures[0] rescue ''),
                                claim_member_ids:      (ins_policy.match(//).captures[0] rescue ''),
                                relation_to_sub:       (ins_policy.match(//).captures[0] rescue ''),
                                status:                (ins_policy.match(//).captures[0] rescue ''),
                                subscriber:            (ins_policy.match(//).captures[0] rescue '')
                              },
          lang:               (record.match(/Lang:\s*(.*)/xi).captures[0] rescue ''),
          last_visit:         (record.match(/last visit:\s*(\d{1,2}\/\d{1,2}\/\d{2,4})/i).captures[0] rescue ''),
          marital:            (record.match(/Marital:\s*(\w*)/i).captures[0] rescue ''),
          mobile:             (record.match(/mobile:\s\((\d{3})\)\s(\d{3})-(\d{4})/i).captures.join('') rescue ''),
          name:               (record.match(/(?<= \d{4})(.*?)(?= Default\sAccount)/xi).captures[0] rescue ''),
          patient_number:     ((record.match(/(\d{4}).*(?= Default\sAccount:)/xim).captures[0] rescue '') || '0000000'),
          race_ethnicity:     (record.match(/Race.*Ethnicity:(.*)Employer:/xm).captures[0] rescue ''),
          referral_src:       (record.match(/Referral\sSrc:\s*(.*?)Referring:/i).captures[0] rescue ''),
          referring:          (record.match(/Referring:(.*?)Emergency/i).captures[0] rescue ''),
          registered:         (record.match(/((?<= Registered:)|\d{5})\s*(\d{1,2}\/\d{1,2}\/\d{4})((?! \s\-\s10\/28\/2015)|Race)/xm).captures[1]  rescue ''),
          sex:                (record.match(/(?<=Sex:)\s*(\w*)Emp\s*Status/i).captures[0] rescue ''),
          ssn:                (record.match(/(?<= SSN:)\s*(\d{3}\-\d{2}\-\d{4})/xm).captures[0] rescue ''),
          work:               (record.match(/(?<= Work:\s)(.*)(?= Referral)/xi).captures.join('') rescue '')
        }
    end
    records_array
  end

  def dump_records_to_csv(records, file_path = 'sample.csv')
    CSV.open(file_path, 'wb') do |csv|
      csv << records.first.select { |k,v| k unless v.respond_to?(:each) }.keys
      records.each do |record|
        csv << record.select { |k,v| v unless v.respond_to?(:each) }.values
        csv << record.select { |k,v| k if v.respond_to?(:each) }.keys.each do |key|
          csv << record[key].keys
          csv << record[key].values
        end
      end
    end
  end

  def dump_records_to_csvzz(file_path, records_array)
    CSV.open(file, "wb") do |csv|
      records_array.map do |record|
        record.map do |k,v|
          if v.respond_to?(:each)
            csv << record.keys
            dump_records_to_csv(file,v)
          else
            csv
          end
        end
      end
      csv << record.keys
      csv << record.values
    end
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