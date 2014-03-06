class Eduskunta

  class Membership
    attr_accessor :organization_id, :role, :start_date, :end_date

    def initialize(params = {})
      params.each { |k, v| public_send("#{k}=", v) }
    end

    def to_hash
      return Hash[%w(organization_id role start_date end_date).map { |name| 
        [ name.to_sym, public_send(name) ]
      }]
    end

    # May return multiple objects
    def self.from_str(text)
      # strip out historic names. 
      # Must happen before parsing, as they include dates
      text.gsub!(/\( [^\)]+ \)/x, '')  
      posn, dates = parse_membership(text)
      return dates.collect { |d|
        self.new({
          :organization_id => organization_id_from(posn), 
          :role       => role_from(posn),
          :start_date => d[0],
          :end_date   => d[1],
        })
      }
    end

    # National Coalition Party 26.03.1983 -
    # Swedish Parliamentary Group 21.03.1987 - 23.03.1995, 05.01.2007 - 20.03.2007, 05.09.2013 -
    # The Finns Party Parliamentary Group (True Finns Party - 20.08.2011) 20.04.2011 -
    # The Finns Party Parliamentary Group (Finnish Rural Party Parliamentary Group - 25.10.1995, True Finns Party 26.10.1995 - 20.08.2011) 26.03.1983 - 23.03.1995, 20.04.2011 -
    # Minister for Foreign Trade (Lipponen II)  15.04.1999 - 03.01.2002, 
    def self.parse_membership(str)
      date_re = /\d{2}\.\d{2}\.\d{4}/
      range_re = /#{date_re} \s+-\s+ #{date_re}? \s*,?\s*/x
      dates = []
      str.gsub!(range_re) { |range|
        dates << range.scan(date_re).collect { |d| Date.find_in(d) }
        ''
      }
      return str.strip, dates
    end

  end

  class Cabinet < Membership
    require 'json'
    @@posts = JSON.parse(File.read('posts.json'))

    def self.organization_id_from(posn) 
      "popit.eduskunta/council-of-state"
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

    def self.organization_id_from (name)
      match = @@parties.find{ |p| p['other_names'].find { |n| n['name'] == name } }
      return match['id'] if match
      raise "No such party: <#{name}>"
    end

    def self.role_from (name)
      'MP'
    end

  end

  class Scraper

    require 'open-uri'
    require 'nokogiri'

    @@PARL_URL = 'http://www.eduskunta.fi'
    
    # TODO try to detect whether the file is EN or FI and delegate
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
        :death_date => death_date,
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

    def contact_details 
      return [
        { 
          :type => "phone",
          :value => phone,
        },
      ]
    end

    def our_id
      "popit.eduskunta/person/" + official_id
    end

    def council_of_state
      council_of_state_raw.flat_map { |cs| Cabinet.from_str(cs) }.collect { |p| p.to_hash }
    end

    def parties
      parties_raw.flat_map { |p| Party.from_str(p) }.collect{ |p| p.to_hash }
    end

  end

  class Scraper::EN < Scraper

    def name
      return @noko.at('div.subhead h4').text.strip
    end

    def fullname
      return infotable.xpath('tr[contains(th,"Full name:")]/td').text.gsub(/\s+/, ' ')
    end

    def phone 
      return infotable.xpath('tr[contains(th,"Telephone:")]/td').text
    end

    def birth_date
      birth = infotable.xpath('tr[contains(th,"Date and place of birth:")]/td').text
      return Date.find_in(birth)
    end

    def death_date
      # Currently EN pages are of sitting MPs, so this shouldn't exist
      nil
    end

    def official_id
      french = @noko.at('#edustaja-alku a:nth-child(4)')
      /hnro\=(\d+)/.match(french['href']) and return $1 or raise "No ID in #{french['href']}"
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

    def parties_raw
      return @noko.xpath('//table/tr[contains(th,"Parliamentary groups:")]/td/ul/li').collect { |li| li.text }
    end

    def infotable
       @infotable ||= @noko.at('table.datatable') or raise "No infotable"
    end

  end

  class Scraper::FI < Scraper::EN

    def name
      @noko.at_xpath('//table/tbody/tr[contains(td[1],"Kansanedustajana")]/td[1]//b[1]').text
    end

    def fullname
      @noko.xpath('//table/tbody/tr[contains(td[1],"nimi")]/td[2]').text.gsub(/\s+/, ' ')
    end

    def phone 
      nil
    end

    def birth_date
      birth = @noko.xpath('//table/tbody/tr[contains(td[1],"Syntym")]/td[2]').text.gsub(/\s+/, ' ')
      return Date.find_in(birth)
    end

    def death_date
      death = @noko.xpath('//table/tbody/tr[contains(td[1],"Kuolinaika")]/td[2]').text.gsub(/\s+/, ' ')
      return Date.find_in(death)
    end

    def official_id
      # TODO there must be a better way than this...
      File.basename(@file.path)
    end

    #TODO add the other language links too
    def links
      [{}]
    end

    def email
      nil
    end

    def image
      ''
    end

    def council_of_state_raw
      []
    end

    def parties_raw
      []
    end

  end

  def Date.find_in(str, silent=false)
    /(\d{2})\.(\d{2})\.(\d{4})*/.match(str) and return Date.new($3.to_i, $2.to_i, $1.to_i).to_s
    return nil if silent
    raise "No date in #{str}"
  end

end


