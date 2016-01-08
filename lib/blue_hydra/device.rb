class BlueHydra::Device

  MAC_REGEX    = /^((?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2})$/i

  include DataMapper::Resource

  property :id,                       Serial
  property :address,                  String
  property :oui,                      Text
  property :peer_address,             String
  property :peer_address_type,        String
  property :peer_address_oui,         String
  property :classic_major_class,      String
  property :classic_minor_class,      String
  property :role,                     String
  property :lmp_version,              String
  property :manufacturer,             String
  property :features,                 String
  property :firmware,                 String
  property :channels,                 String
  property :name,                     String
  property :classic_16_bit_service_uuids, Text
  property :le_16_bit_service_uuids,  Text
  property :classic_class,            Text

  def self.update_or_create_from_result(result)

#     File.write("/opt/pwnix/BLUE_HYDRA_#{Time.now.to_i}.json", [
#       result.inspect,
#       JSON.pretty_generate(result)
#     ].join("\n\n\n"))

    result = result.dup

    address = result[:address].first

    record = self.all(address: address).first || self.new

    attrs = %w{
      address
      oui
      peer_address
      peer_address_type
      peer_address_oui
      role
      lmp_version
      manufacturer
      features
      firmware
      channels
      name
      classic_major_class
      classic_minor_class
    }.map(&:to_sym)

    if result[:le_16_bit_service_uuids]
      BlueHydra.logger.debug( "#{address} SHOULD HAVE LE 16 BIT SERVICE UUIDS")
      record.le_16_bit_service_uuids = result[:le_16_bit_service_uuids]
    end

    if result[:classic_16_bit_service_uuids]
      BlueHydra.logger.debug( "#{address} SHOULD HAVE CLASSIC 16 BIT SERVICE UUIDS")
      record.classic_16_bit_service_uuids = result[:classic_16_bit_service_uuids]
    end

    if result[:classic_class]
      BlueHydra.logger.debug( "#{address} SHOULD HAVE CLASSIC CLASS")
      record.classic_class = result[:classic_class]
    end

    attrs.each do |attr|
      if result[attr]

        if result[attr].uniq.count > 1
          BlueHydra.logger.debug(
            "#{address} multiple values detected for #{attr}: #{result[attr].inspect}. Using first value..."
          )
        end

        new_val     = result[attr].first
        current_val = record[attr]

        unless new_val == current_val
          record[attr] = result.delete(attr).uniq.first
          BlueHydra.logger.debug(
            "#{address} updating #{attr} from #{current_val.inspect} to #{new_val}"
          )
        end

        unless result.empty?
          BlueHydra.logger.debug(
            "#{address} updated. unused values: #{result.inspect}"
          )
        end

        if record.valid?
          record.save
        else
          BlueHydra.logger.warn(
            "#{address} can not save. attrs: #{ record.attributes.inspect }"
          )
        end
      end
    end
  end

  # NOTE: returns raw json...
  def classic_class
    self[:classic_class] || '[]'
  end

  def classic_class=(new_classes)
     new = new_classes.flatten.uniq.reject{|x| x =~ /^0x/}
     current = JSON.parse(self.classic_class)
     self[:classic_class] = JSON.generate((new + current).uniq)
  end

  # NOTE: returns raw json...
  def classic_16_bit_service_uuids
    self[:classic_16_bit_service_uuids] || '[]'
  end

  def classic_16_bit_service_uuids=(new_uuids)
     new = new_uuids.reject{|x| x =~ /^0x/}
     new.map!{|x| x.scan(/(.*) \(0x/).flatten.first}
     current = JSON.parse(self.classic_16_bit_service_uuids)
     self[:classic_16_bit_service_uuids] = JSON.generate((new + current).uniq)
  end

  # NOTE: returns raw json...
  def le_16_bit_service_uuids
    self[:le_16_bit_service_uuids] || '[]'
  end

  def le_16_bit_service_uuids=(new_uuids)
     new = new_uuids.reject{|x| x =~ /^0x/}
     new.map!{|x| x.scan(/(.*) \(0x/).flatten.first}
     current = JSON.parse(self.le_16_bit_service_uuids)
     self[:le_16_bit_service_uuids] = JSON.generate((new + current).uniq)
  end
end
