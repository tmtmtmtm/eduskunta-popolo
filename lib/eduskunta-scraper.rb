class Eduskunta

  class Membership
    attr_accessor :name, :organization_id, :start_date, :end_date

    def initialize(params = {})
      params.each { |k, v| instance_variable_set("@#{k}", v) }
    end

    def to_hash
      return {
        :organization_id => organization_id,
        :start_date => start_date,
        :end_date => end_date,
      }.reject { |k,v| v.nil? }
    end
    
    # National Coalition Party 26.03.1983 -
    # Swedish Parliamentary Group 21.03.1987 - 23.03.1995, 05.01.2007 - 20.03.2007, 05.09.2013 -
    # The Finns Party Parliamentary Group (True Finns Party - 20.08.2011) 20.04.2011 -
    # The Finns Party Parliamentary Group (Finnish Rural Party Parliamentary Group - 25.10.1995, True Finns Party 26.10.1995 - 20.08.2011) 26.03.1983 - 23.03.1995, 20.04.2011 -
    # 
    # Minister for Foreign Trade (Lipponen II)  15.04.1999 - 03.01.2002, 
    def self.parse_membership(str)
      date_re = /\d{2}\.\d{2}\.\d{4}/
      range_re = /#{date_re}\s+-\s+#{date_re}\s*,?\s*/
      dates = []
      str.gsub!(range_re) { |range|
        dates << range.scan(date_re).collect { |d| Date.find_in(d) }
        ''
      }
      str.gsub!(/#{date_re}\s*\-\s*/) { |range|
        dates << range.scan(date_re).collect { |d| Date.find_in(d) }
        ''
      }
      return str.strip, dates
    end

  end

  class Cabinet < Membership
    attr_accessor :role

    require 'json'

    @@posts = JSON.parse(File.read('posts.json'))

    def to_hash
      return {
        :organization_id => organization_id,
        :role => role,
        :start_date => start_date,
        :end_date => end_date,
      }.reject { |k,v| v.nil? }
    end

    def organization_id 
      "popit.eduskunta/council-of-state"
    end

    def self.from_str (text)
      text.gsub!(/\( [^\)]+ \)/x, '')  
      posn, dates = parse_membership(text)
      return dates.collect { |d|
        self.new({
          :role       => role_from(posn),
          :start_date => d[0],
          :end_date   => d[1],
        })
      }
    end

    def self.role_from (name)
      match = @@posts.find{ |p| p['role'] == name } || @@posts.find{ |p| (p['other_labels'] || []).find { |n| n['name'] == name } }
      abort "No such post #{name}" unless match 
      return match['role']
    end


  end

  class Party < Membership

    require 'json'

    @@parties = JSON.parse(File.read('parties.json'))

    def self.name_to_id(name)
      match = @@parties.find{ |p| p['other_names'].find { |n| n['name'] == name } }
      return match['id'] if match
      raise "No such party: <#{name}>"
    end

    # May return multiple objects
    def self.from_str(text)
      # strip out historic party names. 
      # Must happen before parsing, as they include dates
      text.gsub!(/\( [^\)]+ \)/x, '')  
      party, dates = parse_membership(text)
      return dates.collect { |d|
        self.new({
          :name       => party,
          :organization_id => name_to_id(party), 
          :start_date => d[0],
          :end_date   => d[1],
        })
      }
    end

  end

  class Scraper

    require 'open-uri'
    require 'nokogiri'

    @@PARL_URL = 'http://www.eduskunta.fi'
    
    def initialize(file)
      @file = file
      @noko = Nokogiri::HTML(file.read)
    end

    def as_hash 
      return { 
        :id => our_id,
        :name => name,
        :family_name => family_name,
        :given_names => given_names,
        :identifiers => identifiers,
        :email => email,
        :birth_date => birth_date,
        :image => image,
        :contact_details => contact_details,
        :links => links,
        :memberships => memberships,
      }
    end

    def memberships
      combined = council_of_state + parties
      combined.sort_by { |m| m[:start_date] }.collect { |i| i.reject { |k, v| v.nil? } }
    end


    def name
      return @noko.at('div.subhead h4').text.strip
    end

    def fullname
      return infotable.xpath('tr/th[.="Full name: "]/following-sibling::td').text.gsub(/\s+/, ' ')
    end

    def family_name
      fullname.gsub(/,.*/, '').strip
    end
    
    def given_names 
      fullname.gsub(/.*?,/, '').strip
    end

    def identifiers
      return [{
        :identifier => official_id,
        :scheme => 'eduskunta.fi',
      }]
    end

    def phone 
      return infotable.xpath('tr/th[.="Telephone: "]/following-sibling::td').text
    end

    def contact_details 
      return [
        { 
          :type => "phone",
          :value => phone,
        },
      ]
    end

    def birth_date
      birth = infotable.xpath('tr/th[.="Date and place of birth: "]/following-sibling::td').text
      return Date.find_in(birth)
    end


    def official_id
      french = @noko.at('#edustaja-alku a:nth-child(4)')
      /hnro\=(\d+)/.match(french['href']) and return $1 or raise "No ID in #{french['href']}"
    end

    def our_id
      "popit.eduskunta/person/" + official_id
    end

    #TODO add the other language links too
    def links
      return [ {
        :url => "http://www.eduskunta.fi/triphome/bin/hex5000.sh?hnro=#{official_id}&kieli=en",
        :note => "Eduskunta.fi (en)",
      }]
    end

    def email
      return infotable.css('.emailAddress').text.gsub(/\[at\]/, '@')
    end

    def image
      portrait = @noko.at('img.portrait')
      return @@PARL_URL + portrait['src']
    end

    def council_of_state_raw
      cos_table = @noko.xpath('//h3[.="Member in the Council of State"]/following-sibling::table/tr//ul/li').collect { |li| li.text }
    end

    def council_of_state
      council_of_state_raw.collect { |cs| Cabinet.from_str(cs) }.flatten.collect { |p| p.to_hash }
    end

    def parties_raw
      return @noko.xpath('//table/tr/th[.="Parliamentary groups: "]/following-sibling::td/ul/li').collect { |li| li.text }
    end

    def parties
      parties_raw.collect { |p| Party.from_str(p) }.flatten.collect{ |p| p.to_hash }
    end

    def infotable
       @infotable ||= @noko.at('table.datatable') or raise "No infotable"
    end

  end

  def Date.find_in(str, silent=false)
    /(\d{2})\.(\d{2})\.(\d{4})*/.match(str) and return Date.new($3.to_i, $2.to_i, $1.to_i).to_s
    return nil if silent
    raise "No date in #{str}"
  end

end


