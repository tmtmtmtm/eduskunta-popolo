class Eduskunta

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
      }
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
      return _find_date_in(birth)
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

    def infotable
       @infotable ||= @noko.at('table.datatable') or raise "No infotable"
    end

    private

    def _find_date_in(str)
      /^(\d{2})\.(\d{2})\.(\d{4})*/.match(str) and return [$3,$2,$1].join("-") or raise "No date in #{str}"
    end

  end
end


